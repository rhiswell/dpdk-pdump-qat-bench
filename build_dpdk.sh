#!/bin/bash

set -x
set -eui pipefail

RTE_SDK=/root/DPDK/dpdk-18.05

cd ${RTE_SDK} && git pull

make config T=x86_64-native-linuxapp-gcc
sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config
make EXTRA_LDLIBS=-lz -j16 >/dev/null
