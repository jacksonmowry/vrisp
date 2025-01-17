#!/usr/bin/env bash
set -euo pipefail

readonly NUM_ROWS=260
PROCESSORS=(risp vrisp)

main() {
    if [ $# -ne 1 ] && [ $# -ne 2 ]; then
        echo "usage: $0 experiment_prefix [vector]"
        exit 1
    fi

    local experiment_prefix="${1}"

    if [ -n "${2:-}" ]; then
        PROCESSORS+=(vr_full vr_fired vr_synapses vr_dvlen)
    fi

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

        if [ -n "${2:-}" ]; then
            vr_full=($(for activity_percentage in {0..100}; do
                bin/dbscan_app_vrisp_vector_full "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
            done))

            vr_fired=($(for activity_percentage in {0..100}; do
                bin/dbscan_app_vrisp_vector_fired "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
            done))

            vr_synapses=($(for activity_percentage in {0..100}; do
                bin/dbscan_app_vrisp_vector_synapses "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
            done))

            vr_dvlen=($(for activity_percentage in {0..100}; do
                bin/dbscan_app_vrisp_vector_dvlen "${temp_file}" "${activity_percentage}" 10 | awk -F':' '{ printf("%.8f ", 1/$2) }'
            done))
        fi

        printf '#+PLOT: title:"DBScan Epsilon: %s, Min. Pts.: %s"\n' "${epsilon}" "${min_pts}"
        printf '#+PLOT: file:"%s_dbscan_%s_%s.svg"\n' "${experiment_prefix}" "${epsilon}" "${min_pts}"
        printf '#+PLOT: set:"rmargin 8" set:"size ratio 0.5" set:"yrange [0:*]" with:"lines lw 2"\n'
        printf '#+PLOT: set:"xlabel %s" set:"ylabel %s"\n' "'Activity Percent'" "'Frames per Second'"
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

                printf '%d%% ' "${i}"

                printf '%s ' "${risp[${i}]}"
                printf '%s ' "${vrisp[${i}]}"
                if [ -n "${2:-}" ]; then
                    printf '%s ' "${vr_full[${i}]}"
                    printf '%s ' "${vr_fired[${i}]}"
                    printf '%s ' "${vr_synapses[${i}]}"
                    printf '%s ' "${vr_dvlen[${i}]}"
                fi

                printf '|\n'
            done
        } | column --table -o ' | ' | sed 's/| //;s/ |$//'
    done

    return 0
}

temp_file=$(mktemp)
trap 'rm "${temp_file}"' 0 2 3 15

main "${@}"
