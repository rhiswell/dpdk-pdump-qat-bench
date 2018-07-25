#!/bin/bash

set -x
set -eo pipefail

dataset_id=${1:-}

function print_usage_and_die
{
    echo "Usage: $0 <dataset_id>"
    exit 1
}

[[ -z "${dataset_id}" ]] && print_usage_and_die

CALGARY_URL=http://www.data-compression.info/files/corpora/largecalgarycorpus.zip

function prepare_calgary
{
    wget -O /tmp/largecalgary.zip $CALGARY_URL && \
        unzip -c /tmp/largecalgary.zip "*" > calgary && \
        rm /tmp/largecalgary.zip
}

# Convert raw data into pcap file through `lo`
function gen_pcap
{
    local dataset_id=$1

    test -e ${dataset_id} || echo "${dataset_id} doesn't exist"

    sudo ip link set dev lo mtu 1500

    python3 -m http.server 65535 --bind 127.0.0.1 & http_server_pid=$!
    # Refer to https://askubuntu.com/questions/746029/how-to-start-and-kill-tcpdump-within-a-script
    rm -f ${dataset_id}.pcap && sudo tcpdump -U -i lo -s 1500 -w ${dataset_id}.pcap 'port 65535' & tcpdump_pid=$!
    sleep 5

    wget -qO /dev/null http://127.0.0.1:65535/${dataset_id}

    kill $http_server_pid
    sleep 5
    sudo kill -INT $tcpdump_pid
}

gen_pcap ${dataset_id}
