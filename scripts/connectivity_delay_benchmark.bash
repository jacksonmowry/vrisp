#!/usr/bin/env bash
set -euo pipefail

PROCESSORS=(risp vrisp vrisp_swar)

# `generate_network` takes an empty network, a total number of neurons,
#  a delay_max, and a number of input neurons, returning a
#  json copy of the new network
# parameters:
#  $1: empty_network
#  $2: total_neurons
#  $3: delay_max (a number between 1-255)
#  $4: input_count
generate_network() {
    local empty_network="${1}"
    local total_neurons="${2}"
    local delay_max="${3}"
    local input_count="${4}"

    {
        printf 'FJ\n'
        printf '%s\n' "${empty_network}"

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

                if (((RANDOM % 100 + 1) <= 50)); then
                    printf 'AE %d %d\n' "${i}" "${j}"
                    printf 'SEP %d %d Delay %d\n' "${i}" "${j}" "$((RANDOM % delay_max + 1))"
                    total_synapses=$((total_synapses + 1))
                fi
            done
        done

        if [ "${total_synapses}" -eq 0 ]; then
            printf 'AE %d %d\n' 0 "$((total_neurons - 1))"
            printf 'SEP %d %d Delay %d\n' 0 "$((total_neurons - 1))" 1
        fi

        printf 'SEP_ALL Weight 1\n'
        printf 'SORT Q\n'
        printf 'TJ\n'
    } | framework-open/bin/network_tool
}

main() {
    if [ $# -ne 6 ] && [ $# -ne 7 ]; then
        printf 'usage: %s experiment_prefix empty_network num_neurons num_inputs total_timesteps activity_percent [vector_mode]\n' "${0}"
        exit 1
    fi

    local experiment_prefix="${1}"
    local empty_network="${2}"
    local num_neurons="${3}"
    local num_inputs="${4}"
    local total_timesteps="${5}"
    local activity_percent="${6}"
    local vector="${7:-}"

    if [ -n "${vector}" ]; then
        PROCESSORS+=(vr_full vr_fired vr_synapses)
    fi

    risp=()
    vrisp=()
    vrisp_full=()

    for max_delay in {1..254}; do
        test_empty_network=$(jq --arg max_delay "${max_delay}" '.Properties.edge_properties[0].max_value = ($max_delay | tonumber) | .Associated_Data.proc_params.max_delay = ($max_delay | tonumber)' "${empty_network}")

        test_network=$(generate_network "${test_empty_network}" "${num_neurons}" "${max_delay}" "${num_inputs}")

        risp+=("$(bin/connectivity_app_risp <(echo "${test_network}") "${activity_percent}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }')")

        vrisp_network=$(sed -e 's/risp/vrisp/' -e "s/\"discrete\": true,/\"tracked_timesteps\": $((max_delay + 1)),/" <<<"${test_network}")

        vrisp+=("$(bin/connectivity_app_vrisp <(echo "${vrisp_network}") "${activity_percent}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }')")
        vrisp_swar+=("$(bin/connectivity_app_vrisp_swar <(echo "${vrisp_network}") "${activity_percent}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }')")
        if [ -n "${vector}" ]; then
            vrisp_full+=("$(bin/connectivity_app_vrisp_vector_full <(echo "${vrisp_network}") "${activity_percent}" "${total_timesteps}" | head -1 | awk -F':' '{ printf("%.8f ", $2) }')")
        fi
    done

    readonly fan_out="0.50"
    printf '#+PLOT: title:"%s Time Steps: Neurons: %s, Mean Fan-out: %.2f"\n' "${total_timesteps}" "${num_neurons}" "${fan_out}"
    printf '#+PLOT: file:"%s_%s_%s.svg"\n' "${experiment_prefix}" "${num_neurons}" "${fan_out/\./p}"
    printf '#+PLOT: set:"rmargin 8" set:"size ratio 0.5" set:"yrange [0:*]" with:"lines lw 2"\n'
    printf '#+PLOT: set:"xlabel %s" set:"ylabel %s"\n' "'Max Delay'" "'Runtime (seconds)'"
    printf '#+PLOT: ind:1 set:"key below horizontal"\n'
    printf '#+PLOT: labels:("x" '
    for proc in "${PROCESSORS[@]}"; do
        printf '"%s" ' "${proc}"
    done
    printf ')\n'
    {
        printf '| _ '
        for proc in "${PROCESSORS[@]}"; do
            printf '%s ' "${proc}"
        done
        printf '|\n'

        for i in "${!risp[@]}"; do
            printf '| '

            printf '%d ' "$((i + 1))"

            printf '%s ' "${risp[${i}]}"
            printf '%s ' "${vrisp[${i}]}"
            printf '%s ' "${vrisp_swar[${i}]}"
            if [ -n "${vector}" ]; then
                printf '%s ' "${vr_full[${i}]}"
                # printf '%s ' "${vr_fired[${i}]}"
                # printf '%s ' "${vr_synapses[${i}]}"
            fi

            printf '|\n'
        done
        :
    } | column --table -o ' | ' | sed 's/| //;s/ |$//'
}

temp_file=$(mktemp)
trap 'rm -f "${temp_file}"' 0 2 3 15

main "${@}"
