#!/usr/bin/env bash
set -euo pipefail

PROCESSORS=(risp vrisp)

# `generate_network` takes an empty network, a total number of neurons,
#  a connectivity chance, and a number of input neurons, returning a
#  json copy of the new network
# parameters:
#  $1: empty_network
#  $2: total_neurons
#  $3: connectivity_chance (a number between 0-100)
#  $4: input_count
generate_network() {
    local empty_network="${1}"
    local total_neurons="${2}"
    local connectivity_chance="${3}"
    local input_count="${4}"

    {
        printf 'FJ %s\n' "${empty_network}"

        printf 'AN '
        for ((i = 0; i < total_neurons; i++)); do
            printf '%d ' "${i}"
        done
        printf '\n'

        local -A arr=()
        while [[ "${#arr[@]}" -lt "${input_count}" ]]; do
            arr["$((RANDOM % total_neurons))"]=true
        done

        printf 'AI '
        for i in "${!arr[@]}"; do
            printf '%d ' "${i}"
        done
        printf '\n'

        printf 'AO '
        for ((i = 0; i < total_neurons; i++)); do
            if [[ -z "${arr[${i}]:-}" ]]; then
                printf '%d ' "${i}"
            fi
        done
        printf '\n'

        printf 'SNP_ALL Threshold 1\n'

        local total_synapses=0
        for ((i = 0; i < total_neurons; i++)); do
            for ((j = 0; j < total_neurons; j++)); do
                if ((i == j)); then
                    continue
                fi

                if (((RANDOM % 100 + 1) <= connectivity_chance)); then
                    printf 'AE %d %d\n' "${i}" "${j}"
                    total_synapses=$((total_synapses + 1))
                fi
            done
        done

        if [ "${total_synapses}" -eq 0 ]; then
            printf 'AE %d %d\n' 0 "$((total_neurons - 1))"
        fi

        printf 'SEP_ALL Weight 1\n'
        printf 'SEP_ALL Delay 1\n'
        printf 'SORT Q\n'
        printf 'TJ\n'
    } | framework-open/bin/network_tool
}

main() {
    if [ $# -ne 6 ] && [ $# -ne 7 ]; then
        printf 'usage: %s empty_network num_neurons connectivity_chance num_inputs total_timesteps activity_max [vector_mode]\n' "${0}"
        exit 1
    fi

    local empty_network="${1}"
    local num_neurons="${2}"
    local connectivity_chance="${3}"
    local num_inputs="${4}"
    local total_timesteps="${5}"
    local activity_max="${6}"
    local vector="${7:-}"

    if [ -n "${vector}" ]; then
        PROCESSORS+=(vr_full vr_fired vr_synapses)
    fi

    generate_network "${empty_network}" "${num_neurons}" "${connectivity_chance}" "${num_inputs}" >"${temp_file}"

    risp=($(for ((activity_percentage = 0; activity_percentage <= activity_max; activity_percentage++)); do
        bin/connectivity_app_risp "${temp_file}" "${activity_percentage}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }'
    done))

    sed -i -e 's/risp/vrisp/' -e 's/"discrete": true,/"tracked_timesteps": 2,/' "${temp_file}"

    vrisp=($(for ((activity_percentage = 0; activity_percentage <= activity_max; activity_percentage++)); do
        bin/connectivity_app_vrisp "${temp_file}" "${activity_percentage}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }'
    done))

    if [ -n "${vector}" ]; then
        vr_full=($(for ((activity_percentage = 0; activity_percentage <= activity_max; activity_percentage++)); do
            bin/connectivity_app_vrisp_vector_full "${temp_file}" "${activity_percentage}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }'
        done))

        vr_fired=($(for ((activity_percentage = 0; activity_percentage <= activity_max; activity_percentage++)); do
            bin/connectivity_app_vrisp_vector_fired "${temp_file}" "${activity_percentage}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }'
        done))

        vr_synapses=($(for ((activity_percentage = 0; activity_percentage <= activity_max; activity_percentage++)); do
            bin/connectivity_app_vrisp_vector_synapses "${temp_file}" "${activity_percentage}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }'
        done))
    fi

    printf 'Total Sim Time: Neurons: %s, Synapses: %s, Average Fan-out: %.2f, Connectivity Chance: %s%%, Timesteps: %s\n' "${num_neurons}" "$(jq '.Edges | length' "${temp_file}")" "$(jq '(.Edges | length) / (.Nodes | length)' "${temp_file}")" "${connectivity_chance}" "${total_timesteps}"
    {
        printf '| _ '
        for proc in "${PROCESSORS[@]}"; do
            printf '%s ' "${proc}"
        done
        printf '|\n'

        for i in "${!risp[@]}"; do
            printf '| '

            printf '%d%% ' "${i}"

            printf '%s ' "${risp[${i}]}"
            printf '%s ' "${vrisp[${i}]}"
            if [ -n "${vector}" ]; then
                printf '%s ' "${vr_full[${i}]}"
                printf '%s ' "${vr_fired[${i}]}"
                printf '%s ' "${vr_synapses[${i}]}"
            fi

            printf '|\n'
        done
        :
    } | column --table -o ' | ' | sed 's/| //;s/ |$//'
}

temp_file=$(mktemp)
trap 'rm -f "${temp_file}"' 0 2 3 15

main "${@}"
