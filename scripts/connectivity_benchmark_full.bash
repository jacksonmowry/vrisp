#!/usr/bin/env bash
set -euo pipefail

main() {
    for num_neurons in 5 10 15 20 25 50 75 100 150 175 200 225 250; do
        for connectivity_chance in 5 10 15 20 25 50 75 100; do
            printf "Testing neurons: %s, connectivity: %s, activity: %s\n" "${num_neurons}" "${connectivity_chance}" "${activity_percentage}" >/dev/stderr
            bash scripts/connectivity_benchmark.bash networks/risp_1.json "${num_neurons}" "${connectivity_chance}" 3 1000 100
        done
    done
}

main "${@}"
