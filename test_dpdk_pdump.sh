#!/bin/bash
#
# Architecture overview:
#
#   ALICE (remote)                          BOB (remote)
# |---------------|                     |--------|-------|
# |     PKTGEN    |-10Gbps TCP traffic->| RECVER + PDUMP |
# |---------------|                     |--------|-------|
#         ^                                      ^
#         |--------------------------------------|
#         |
# |---------------|
# | ./this_script |
# |---------------|
#       LOCAL
#

set -ueo pipefail


CMD=${1:-test}
ALICE=${2:-qat0}
BOB=${3:-qat1}


function app_echo
{
    local msg=${1:-}
    echo "TEST_DPDK_PDUMP.SH: $msg"
}


function print_usage_then_die
{
    app_echo "Usage: $0 <command> <sender> <receiver>"
    exit 1
}


([[ -z "$CMD" ]] || [[ -z "$ALICE" ]] || [[ -z "$BOB" ]]) && print_usage_then_die


mkdir -p output


function tell_synopsis
{
    echo -e "\n\n\n===STAGE 4: parse logs and give synopsis"
    test -e output/pktgen_tx.log && test -e output/pktgen_rx.log && test -e output/pdump.log

    echo -e "Total sent:     $(cat output/pktgen_tx.log | grep "Total" | tail -n1 | awk -F' ' '{ print $4 }')"
    echo -e "Total received: $(cat output/pktgen_rx.log | grep "Total" | tail -n1 | awk -F' ' '{ print $4 }')"
    cat output/pdump.log | grep -A4 "STATS" | tail -n4
}


function visualize_diff
{
    echo -e "\n\n\n===STAGE 4: do render graph of difference between input/val2017.pcap (origin) and /tmp/rx.pcap (received)..."
    test -e pdiff.py && test -e output/rx.pcap
    ./pdiff.py input/val2017.pcap output/rx.pcap
}


function run_test
{
    echo -e "\n\n\n===STAGE X: test start"

    # \begin test
    test -e ./remote_run && test -e pdumpd.sh && test -e receiverd.sh && test -e issue_traffic.sh

    echo -e "\n\n\n===STAGE 0: run receiverd"
    ./remote_run $BOB receiverd.sh 'restart'
    echo -e "\n\n\n===STAGE 1: run pdumpd"
    ./remote_run $BOB pdumpd.sh 'restart /tmp/rx.pcap'
    echo -e "\n\n\n===STAGE 2: issue traffic"
    ./remote_run $ALICE issue_traffic.sh 'pcaplist.txt'
    # \end test

    # \begin clean resources
    echo -e "\n\n\n===STAGE 3: kill all detached jobs"
    ./remote_run $BOB pdumpd.sh stop
    ./remote_run $BOB receiverd.sh stop
    # \end clean resources

    # \begin analyze and tell synopsis
    echo -e "\n\n\n===STAGE 4: collect output data and do some analysis"
    scp $ALICE:/var/log/pktgen_tx.log output/pktgen_tx.log
    scp $BOB:/tmp/rx.pcap output/rx.pcap
    scp $BOB:/var/log/pktgen_rx.log output/pktgen_rx.log
    scp $BOB:/var/log/pdump.log output/pdump.log

    tell_synopsis
    #visualize_diff
    # \end analyze and tell synopsis

    echo -e "\n\n\n===STAGE Y: test end"
}


case $CMD in
    test)
        run_test
        ;;
    syno)
        tell_synopsis
        ;;
    diff)
        visualize_diff
        ;;
    *)
        print_usage_then_die
esac


exit 0
