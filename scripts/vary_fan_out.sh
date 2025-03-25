#!/usr/bin/env sh

i=1

printf '| _ | risp | superneuro | vrisp | vrisp-full |\n'
while [ "${i}" -le 256 ]; do
    output=$(sh scripts/connectivity_benchmark_plank.sh networks/risp_15_plus.json 256 256 15 "${i}" 10 25 5000)
    printf '| %d | %s | %s | %s | %s |\n' \
        "${i}" \
        "$(echo "${output}" | sed '1q;d' | awk '{ printf("%0f", $2 ? 1/$2 : 0) }')" \
        "$(echo "${output}" | sed '2q;d' | awk '{ printf("%0f", $2!="n/a" ? 1/$2 : -1) }')" \
        "$(echo "${output}" | sed '3q;d' | awk '{ printf("%0f", $2 ? 1/$2 : 0) }')" \
        "$(echo "${output}" | sed '4q;d' | awk '{ printf("%0f", $2!="n/a" ? 1/$2 : -1) }')"
    i=$((i * 2))
done
