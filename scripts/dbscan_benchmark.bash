#!/usr/bin/env bash
set -euo pipefail

readonly NUM_ROWS=260
readonly PROCESSORS=(risp vrisp vr_full vr_fired vr_synapses)

main() {
    local -a dbscan_params=(1_7 2_18 3_36 4_60 5_90 6_120)

    for test_case in "${dbscan_params[@]}"; do
        local epsilon="${test_case%_*}"
        local min_pts="${test_case#*_}"

        dbscan/bin/dbscan_systolic_full "${NUM_ROWS}" "${epsilon}" "${min_pts}" networks/risp_127.json | framework-open/bin/network_tool >"${temp_file}"

        risp=($(for activity_percentage in {0..100}; do
            bin/dbscan_app_risp "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
        done))

        sed -i -e 's/risp/vrisp/' -e 's/"discrete": true,/"tracked_timesteps": 16,/' "${temp_file}"

        vrisp=($(for activity_percentage in {0..100}; do
            bin/dbscan_app_vrisp "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
        done))

        vr_full=($(for activity_percentage in {0..100}; do
            bin/dbscan_app_vrisp_vector_full "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
        done))

        vr_fired=($(for activity_percentage in {0..100}; do
            bin/dbscan_app_vrisp_vector_fired "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
        done))

        vr_synapses=($(for activity_percentage in {0..100}; do
            bin/dbscan_app_vrisp_vector_synapses "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
        done))

        printf 'DBScan Epsilon: %s, Min. Pts.: %s\n' "${epsilon}" "${min_pts}"
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
                printf '%s ' "${vr_full[${i}]}"
                printf '%s ' "${vr_fired[${i}]}"
                printf '%s ' "${vr_synapses[${i}]}"

                printf '|\n'
            done
        } | column --table -o ' | ' | sed 's/| //;s/ |$//'

        # # TODO remove this, just testing 1_7 for now
        # exit 1
    done

    return 0
}

temp_file=$(mktemp)
trap 'rm "${temp_file}"' 0 2 3 15

main "${@}"
