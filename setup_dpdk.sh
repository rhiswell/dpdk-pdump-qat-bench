#!/bin/bash

set -ueo pipefail

RTE_SDK=/root/DPDK/dpdk-18.05

test -d ${RTE_SDK} && cd ${RTE_SDK}

modprobe uio || true
insmod ./build/kmod/igb_uio.ko || true
./usertools/dpdk-devbind.py -b igb_uio 03:00.0 03:00.1

mkdir -p /mnt/huge
umount /mnt/huge || true
mount -t hugetlbfs nodev /mnt/huge
echo 256 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages

