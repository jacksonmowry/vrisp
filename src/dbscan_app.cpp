#include "framework.hpp"
#include <chrono>
#include <fstream>

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
  if (argc != 4) {
    fprintf(stderr, "usage: %s network_json activity_percent frames\n",
            argv[0]);
    return 1;
  }

  json network_json;
  vector<string> json_source = {argv[1]};
  int activity_denom = stoi(argv[2]);
  size_t total_frames = stoull(argv[3]);

  ifstream fin(argv[1]);
  fin >> network_json;

  Processor *p = nullptr;
  Network *n = load_network(&p, network_json);

  if (!n) {
    fprintf(stderr, "%s: main: Unable to load network.\n", __FILE__);
  }

  std::chrono::duration<double, std::ratio<1>> d =
      std::chrono::duration<double, std::ratio<1>>::zero();

  for (size_t frames = 0; frames < total_frames; frames++) {
    chrono::time_point<chrono::steady_clock> tp = chrono::steady_clock::now();
    for (int outer = 0; outer < 340; outer++) {
      for (int i = 0; i < n->num_inputs(); i++) {
        if ((int)(rand() % 100 + 1) <= activity_denom) {
          p->apply_spike(Spike(i, 0, 1));
        }
      }

      p->run(1);
    }

    d += std::chrono::duration_cast<
        std::chrono::duration<double, std::ratio<1>>>(
        chrono::steady_clock::now() - tp);
  }

  printf("Average frame time: %7.10f\n", d.count() / (double)total_frames);
}
