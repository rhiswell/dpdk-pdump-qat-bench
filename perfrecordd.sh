#!/bin/bash

set -euo pipefail


function app_echo
{
    local m="$1"
    echo "PERFRECORDD.SH: $m"
}


# Emotion at this moment: @#)($*()U)s90f9023u\complicated\sad\disappointed


function print_usage_then_die
{
    app_echo "Usage: $0 <start|stop> [pid] [path to perf data]"
    exit 1
}


CMD=${1:-}
PID=${2:-}
FOUT=${3:-/tmp/perf.data}


[[ -z "$CMD" ]] && print_usage_then_die
[[ "$CMD" = "start" ]] && [[ -z "$PID" ]] && print_usage_then_die


# All the parameters refer to https://github.com/brendangregg/FlameGraph
function do_start
{
    # Well, perf-record will `mv` perf.data to perf.data.old if perf.data already exists
    perf record -F 99 -p $PID -g -o $FOUT > /var/log/perf_record.log 2>&1 & pid=$! && \
        echo -n $! > /var/run/perfrecordd.pid
    app_echo "New perf-record job is running by pid $(cat /var/run/perfrecordd.pid)"
}


function do_stop
{
    (test -e /var/run/perfrecordd.pid && kill -INT $(cat /var/run/perfrecordd.pid) && sleep 2 && app_echo "Old job is killed") || \
        app_echo "WARN: no running perfrecordd"
    (test -e $FOUT && perf script -i $FOUT > $FOUT.out) || \
        app_echo "WARN: perf-record probabily failed to generate perf.data"
    rm -f /var/run/perfrecordd.pid
}


case $CMD in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    *)
        print_usage_then_die
esac
