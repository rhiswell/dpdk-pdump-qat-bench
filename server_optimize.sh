#!/bin/sh

#iptables stop
#ip6tables stop
#systemctl stop irqbalance
set selinux=disabled
ulimit -n 200000
echo 131072 > /proc/sys/net/core/rmem_max
echo 131071 > /proc/sys/net/core/wmem_max
echo 4096 87380 6291456 > /proc/sys/net/ipv4/tcp_rmem
echo 4096 16384 4194304 > /proc/sys/net/ipv4/tcp_wmem
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
echo 50576 64768 98152 > /proc/sys/net/ipv4/tcp_mem
echo 1 > /proc/sys/net/ipv4/tcp_no_metrics_save
echo 1 > /proc/sys/net/ipv4/tcp_orphan_retries
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1025 65535 > /proc/sys/net/ipv4/ip_local_port_range
echo 2000 > /proc/sys/net/ipv4/tcp_max_tw_buckets
echo 5000 > /proc/sys/net/core/netdev_max_backlog
#rmmod ipt_MASQUERADE
#rmmod nf_nat
#rmmod xt_state
#rmmod nf_conntrack_ipv6
#rmmod nf_conntrack_ipv4
#rmmod nf_conntrack
#rmmod nf_defrag_ipv4
