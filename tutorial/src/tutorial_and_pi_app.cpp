#include "framework.hpp"
#include <fstream>
#include <wiringPi.h>

using namespace std;
using namespace neuro;
using nlohmann::json;

Network *load_network(Processor **pp, const json &network_json) {
  Network *net;
  json proc_params;
  string proc_name;
  Processor *p;

  net = new Network();
  net->from_json(network_json);

  p = *pp;
  if (p == nullptr) {
    proc_params = net->get_data("proc_params");
    proc_name = net->get_data("other")["proc_name"];
    p = Processor::make(proc_name, proc_params);
    *pp = p;
  }

  if (p->get_network_properties().as_json() !=
      net->get_properties().as_json()) {
    fprintf(
        stderr,
        "%s: load_network: Network and processor properties do not match.\n",
        __FILE__);
    return nullptr;
  }

  if (!p->load_network(net)) {
    fprintf(stderr, "%s: load_network: Failed to load network.\n", __FILE__);
    return nullptr;
  }

  return net;
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s network_json\n", argv[0]);
    return 1;
  }

  json network_json;
  vector<string> json_source = {argv[1]};

  wiringPiSetupGpio();

  int APin = 17;
  int BPin = 23;

  pinMode(APin, INPUT);
  pinMode(BPin, INPUT);

  pullUpDnControl(APin, PUD_UP);
  pullUpDnControl(BPin, PUD_UP);

  ifstream fin(argv[1]);
  fin >> network_json;

  Processor *p = nullptr;
  Network *n = load_network(&p, network_json);

  if (!n) {
    fprintf(stderr, "%s: main: Unable to load network.\n", __FILE__);
  }

  while (true) {
    int AState = digitalRead(APin);
    int BState = digitalRead(BPin);

    p->apply_spike(Spike(0, 0, AState == LOW));
    p->apply_spike(Spike(1, 0, BState == LOW));

    p->run(2);

    bool output = p->output_count(0);
    printf("A&B: %d\n", output);

    delay(100);
  }
}
