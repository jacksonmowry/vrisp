#!/usr/bin/env sh
# Plain old `sh` this time

export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1

if [ "${#}" -ne 8 ]; then
    echo "usage: ${0} [empty_network.json] [num_input_neurons] [num_output_neurons] [max_delay] [fan_out] [recurrence] [activity_percent] [timesteps]" 2>&1
    exit 1
fi

empty_network="${1}"
num_input_neurons="${2}"
num_output_neurons="${3}"
max_delay="${4}"
fan_out="${5}"
recurrence="${6}"
activity_percent="${7}"
timesteps="${8}"

# Basic error checking
if [ "${fan_out}" -gt "${num_output_neurons}" ]; then
    echo "fan_out (${fan_out}) cannot be > num_output_neurons (${num_output_neurons})" 2>&1
    exit 1
fi

# Network Caching b/c generating these is super slow
if ! [ -d networks/testing_cache ]; then
    mkdir networks/testing_cache
fi

# Check if we've already created this network
if [ -f "networks/testing_cache/${num_input_neurons}_${num_output_neurons}_${max_delay}_${fan_out}_${recurrence}.json" ]; then
    cp "networks/testing_cache/${num_input_neurons}_${num_output_neurons}_${max_delay}_${fan_out}_${recurrence}.json" tmp_network.json
else
    total_neurons=$((num_input_neurons + num_output_neurons))

    # Creates a 2 layer network as parameterized above
    # Places the result in `tmp_network.json`
    (
        echo FJ "${empty_network}"

        # Adding all neurons
        printf 'AN '
        i=0
        while [ "${i}" -lt "${total_neurons}" ]; do
            printf '%s ' "${i}"
            i=$((i + 1))
        done
        printf '\n'

        # Specify Input neurons
        printf 'AI '
        i=0
        while [ "${i}" -lt "${num_input_neurons}" ]; do
            printf '%s ' "${i}"
            i=$((i + 1))
        done
        printf '\n'

        # Specify Output neurons
        printf 'AO '
        i="${num_input_neurons}"
        while [ "${i}" -lt "${total_neurons}" ]; do
            printf '%s ' "${i}"
            i=$((i + 1))
        done
        printf '\n'

        printf 'SNP_ALL Threshold 1\n'

        # Make connections
        i=0
        while [ "${i}" -lt "${num_input_neurons}" ]; do
            # Add `fan_out` connections
            j=0
            while [ "${j}" -lt "${fan_out}" ]; do
                destination_neuron=$((num_input_neurons + ((i + j) % num_output_neurons)))
                printf 'AE %d %d\n' "${i}" "${destination_neuron}"
                printf 'SEP %d %d Delay %d\n' "${i}" "${destination_neuron}" "$(shuf -i 1-"${max_delay}" -n 1)"
                printf 'SEP %d %d Weight %d\n' "${i}" "${destination_neuron}" "$(shuf -i 1-15 -n 1)" # hard coding for now
                j=$((j + 1))
            done

            i=$((i + 1))
        done

        echo TJ tmp_network.json
    ) | framework-open/bin/network_tool

    # Populate the cache
    cp tmp_network.json "networks/testing_cache/${num_input_neurons}_${num_output_neurons}_${max_delay}_${fan_out}_${recurrence}.json"
fi

risp=$(bin/connectivity_app_risp tmp_network.json "${activity_percent}" "${timesteps}" | awk '{ print $4 }')
superneuro=$(python ~/sn/script.py tmp_network.json "$((timesteps / 500))" "0.${activity_percent}" 2>/dev/null | tail -1 | awk '{ print $4 }')
sed -i -e 's/risp/vrisp/' \
    -e '/fire_like_ravens/d' \
    -e '/run_time_inclusive/d' \
    -e 's/"threshold_inclusive": \([[:alnum:]]\+\)//' \
    -e 's/"discrete": true,/"tracked_timesteps": 16,/' \
    -e 's/"spike_value_factor": \(.*\?\),/"spike_value_factor": \1/' \
    tmp_network.json

vrisp=$(bin/connectivity_app_vrisp tmp_network.json "${activity_percent}" "${timesteps}" | awk '{ print $4 }')
vrisp_full=''

if [ -f bin/connectivity_app_vrisp_vector_full ]; then
    vrisp_full=$(bin/connectivity_app_vrisp_vector_full tmp_network.json "${activity_percent}" "${timesteps}" | awk '{ print $4 }')
fi

echo "risp:  ${risp}"
echo "superneuro: ${superneuro}"
echo "vrisp: ${vrisp}"
echo "vrisp_full: ${vrisp_full:-n/a}"
