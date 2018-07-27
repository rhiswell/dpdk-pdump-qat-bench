#!/bin/bash

set -x
set -eui pipefail

RTE_SDK=/root/DPDK/dpdk-18.05

cd ${RTE_SDK}

make config T=x86_64-native-linuxapp-gcc
sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config
make -j8 >/dev/null
