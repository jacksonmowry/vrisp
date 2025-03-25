#!/usr/bin/env sh

i=1

printf '|-  |      |            |       |                  |\n'
printf '| Activity Percent | risp | superneuro | vrisp | vrisp/superneuro |\n'
printf '|-  |      |            |       |                  |\n'
printf '|/  |<     |<           |<      |<                 |\n'
while [ "${i}" -le 100 ]; do
    output=$(sh scripts/connectivity_benchmark_plank.sh networks/risp_15_plus.json 64 64 15 32 10 "${i}" 5000)
    printf '| %d%% | %s | %s | %s | %s |\n' \
        "${i}" \
        "$(echo "${output}" | sed '1q;d' | awk '{ printf("%0f", $2 ? 1/$2 : 0) }')" \
        "$(echo "${output}" | sed '2q;d' | awk '{ printf("%0f", $2!="n/a" ? 1/$2 : -1) }')" \
        "$(echo "${output}" | sed '3q;d' | awk '{ printf("%0f", $2 ? 1/$2 : 0) }')" \
        ':=($3/$4)'
    i=$((i + 2))
done
printf '|-  |      |            |       |                  |\n'
