#!/usr/bin/env bash

temp_file=$(mktemp)
trap 'rm "${temp_file}"' 0 2 3 15
dbscan/bin/dbscan_systolic_full 260 1 7 networks/risp_127.json | framework-open/bin/network_tool >"${temp_file}"

risp_0=$(/usr/bin/time -v bin/dbscan_app_risp "${temp_file}" 0 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
risp_25=$(/usr/bin/time -v bin/dbscan_app_risp "${temp_file}" 25 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
risp_50=$(/usr/bin/time -v bin/dbscan_app_risp "${temp_file}" 50 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
risp_75=$(/usr/bin/time -v bin/dbscan_app_risp "${temp_file}" 75 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
risp_100=$(/usr/bin/time -v bin/dbscan_app_risp "${temp_file}" 100 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')

vrisp_0=$(/usr/bin/time -v bin/dbscan_app_vrisp "${temp_file}" 0 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
vrisp_25=$(/usr/bin/time -v bin/dbscan_app_vrisp "${temp_file}" 25 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
vrisp_50=$(/usr/bin/time -v bin/dbscan_app_vrisp "${temp_file}" 50 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
vrisp_75=$(/usr/bin/time -v bin/dbscan_app_vrisp "${temp_file}" 75 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')
vrisp_100=$(/usr/bin/time -v bin/dbscan_app_vrisp "${temp_file}" 100 10 2>&1 >/dev/null | grep "Maximum resident set size" | awk '{ print $6 }')

{
    printf '_ %s %s\n' "risp" "vrisp"
    printf '0%% %s %s\n' "${risp_0}" "${vrisp_0}"
    printf '25%% %s %s\n' "${risp_25}" "${vrisp_25}"
    printf '50%% %s %s\n' "${risp_50}" "${vrisp_50}"
    printf '75%% %s %s\n' "${risp_75}" "${vrisp_75}"
    printf '100%% %s %s\n' "${risp_100}" "${vrisp_100}"
} | column --table
