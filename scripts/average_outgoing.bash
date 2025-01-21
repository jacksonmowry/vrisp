#!/usr/bin/env bash

main() {
    if [ $# -ne 1 ]; then
        echo "usage: $0 network.json"
        exit 1
    fi
    local network="${1}"

    average=$(jq '(.Edges | length) / (.Nodes | length)' "${network}")
    median=$(jq '(.Nodes | length) as $nlen | [.Edges[].from] | sort | group_by(.) | map(length) | .[(length / 2) - 1]' "${network}")
    # histogram=$(jq '.Edges as $e | [.Nodes | map(.id) | map({id: ., outgoingEdges: ( . as $id | [$e[] | select(.from == $id)] | length) }) | .[].outgoingEdges]' "${network}")

    echo "Average Fan-out:" "${average}"
    echo "Median Fan-out:" "${median}"
}

main "${@}"
