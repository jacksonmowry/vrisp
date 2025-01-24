#!/usr/bin/env bash

main() {
    local procs=(risp vrisp)

    if [ "$#" -gt 3 ]; then
        printf 'usage: %s experiment_prefix [vector]\n' "${0}"
        return 1
    fi

    if [ "${2}" == "vector" ]; then
        procs+=(vrisp_vector_full vrisp_vector_fired vrisp_vector_synapses)
    fi

    local experiment_prefix="${1}"

    for size in {100..1000..50}; do
        local risp_network
        local vrisp_network
        local -a risp=()
        local -a vrisp=()
        local -a vrisp_vector_full=()
        local -a vrisp_vector_fired=()
        local -a vrisp_vector_synapses=()

        if ! risp_network=$(
            cd framework-open/
            bash scripts/bars_stripes.sh "${size}" "${size}"
        ); then
            printf 'Unable to generate bars_stripes network for risp.\n' >&2
            return 1
        fi

        if ! vrisp_network=$(sed -e 's/risp/vrisp/' -e 's/"discrete": true,/"tracked_timesteps": 2,/' -e '/run_time_inclusive/d' -e '/fire_like_ravens/d' -e 's/"threshold_inclusive": true//' -e 's/"spike_value_factor": 1.0,/"spike_value_factor": 1.0/' <<<"${risp_network}"); then
            printf 'Unable to generate bars_stripes network for vrisp.\n' >&2
            return 1
        fi

        for processor in "${procs[@]}"; do
            local network
            if [ "${processor}" == "risp" ]; then
                network="${risp_network}"
            else
                network="${vrisp_network}"
            fi

            if ! mapfile -t "${processor}" < <(for activity in {0..100}; do
                bin/bars_stripes_app_"${processor}" <(echo "${network}") "${activity}" 100 | tail -1 | sed 's/.*: //' | awk '{printf("%.10f ", 1/$1)}'
                printf '\n'
            done); then
                printf 'Unable to run bars_stipes_app on %s.\n' "${processor}" >&2
                return 1
            fi

        done

        printf '#+PLOT: title:"Bars Stripes Calculations per Second %sx%s"\n' "${size}" "${size}"
        printf '#+PLOT: file:"%s_bar_stripe_%s.svg"\n' "${experiment_prefix}" "${size}"
        printf '#+PLOT: set:"rmargin 8" set:"size ratio 0.5" set:"yrange [0:*]" with:"lines lw 2"\n'
        printf '#+PLOT: set:"xlabel %s" set:"ylabel %s"\n' "'Activity Percent'" "'Calculations per Second'"
        printf '#+PLOT: ind:1 set:"key below horizontal"\n'
        printf '#+PLOT: labels:("x"'
        for processor in "${procs[@]}"; do
            printf ' "%s"' "${processor//_/-}"
        done
        printf ')\n'

        {
            printf '|    _  '
            for processor in "${procs[@]}"; do
                printf ' %s ' "${processor}"
            done
            printf '|\n'

            local len="${#risp[@]}"
            for ((activity = 0; activity < len; activity++)); do
                printf '| %3s%% ' "${activity}"
                for processor in "${procs[@]}"; do
                    local -n arr="${processor}"

                    printf ' %s  ' "${arr[activity]}"
                done

                printf '|\n'
            done
        } | column --table -o ' | ' | sed 's/| //;s/ |$//'

    done
}

main "${@}"
