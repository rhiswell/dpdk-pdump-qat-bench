#!/bin/bash

set -x
set -eui pipefail

RTE_SDK=/root/DPDK/dpdk-18.05
PDUMP=/root/DPDK/dpdk-18.05/app/pdump

cd ${RTE_SDK} && git pull

make -C $PDUMP EXTRA_LDLIBS=-lz >/dev/null
