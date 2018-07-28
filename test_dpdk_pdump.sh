#!/bin/bash
#
# This script should execute in local host.
#

set -ueo pipefail

ALICE=${1:-qat0}
BOB=${2:-qat1}


function app_echo
{
    local msg=${1:-}
    echo "TEST_DPDK_PDUMP.SH: $msg"
}


function print_usage_then_die
{
    app_echo "Usage: $0 <sender> <receiver>"
    exit 1
}


([[ -z "$ALICE" ]] || [[ -z "$BOB" ]]) && print_usage_then_die


# \begin collect data
test -e ./remote && test -e pdumpd.sh && test -e receiverd.sh && \
    test -e issue_traffic.sh && test -e pdiff.py
echo -e "\n\n\n===STAGE 0: run receiverd"
./remote $BOB run receiverd.sh 'restart'
echo -e "\n\n\n===STAGE 1: run pdumpd"
./remote $BOB run pdumpd.sh 'restart /tmp/rx.pcap'
echo -e "\n\n\n===STAGE 2: issue traffic"
./remote $ALICE run issue_traffic.sh 'pcaplist.txt'
# \end collect data


# \begin analyzing
echo -e "\n\n\n===STAGE 3: kill all detached jobs"
./remote $BOB run pdumpd.sh stop
./remote $BOB run receiverd.sh stop

# Fetch received pkts.pcap to make comparsion with issued pkts.pcap
echo -e "\n\n\n===STAGE 4: do render graph of difference between input/val2017.pcap (origin) and /tmp/rx.pcap (received)..."
scp -q $BOB:/tmp/rx.pcap output/val2017.rx.pcap && \
    ./pdiff.py input/val2017.pcap output/val2017.rx.pcap
# \end analyzing


exit 0
