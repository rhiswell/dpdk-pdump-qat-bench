#!/bin/bash

set -euo pipefail


function print_usage_then_die
{
    echo "Usage: $0 <bench_id>"
    exit 1
}


# [root@localhost output]# lshw -c disk
#   *-disk
#        description: ATA Disk
#        product: ST1000NX0423
#        physical id: 0.0.0
#        bus info: scsi@0:0.0.0
#        logical name: /dev/sda
#        version: TN03
#        serial: W4704PHA
#        size: 931GiB (1TB)
#        capabilities: partitioned partitioned:dos
#        configuration: ansiversion=5 logicalsectorsize=512 sectorsize=512 signature=00083741
# => 7200 RPM / 128 MB in-disk buffer
function bench_disk_IO_throughput
{
    # Variables: none
    # Workload: none
    # Metrics: sequential write TP
    local input_file=input/web-http-huge.pcap
    local output_file=output/disk_write_tp.csv

    dd if=${input_file} of=/tmp/bench_`date +"%Y%m%d-%H%M%S"` oflag=direct bs=128MB 2>&1 |
        grep -Eo "[0-9]+(.[0-9]+)? MB/s" >${output_file}
}


# tcpdump ip and port http or https -i lo -w https-video.pcap
# ATTENTION 00: should'n use default lo since its MTU is 65535, then tcpreplay this pcap
# will get waring like "Message too long (errno = 90)". Remember to reset MTU to 1500 first.
# ATTENTION 01: actually filter `ip and port http or https` only dump IP packets that
# are greater than common MTU, then cause message-too-long error when doing tcpreplay.
# Here is the right and final filter: there's no filter for now. And I just rewrite the pcap
# with option --mtu-trunc in tcprewrite to fix the warning.
# Finally, I abort the chooce since it will drop some data that will be valuable in testing
# compression algorithm. 
# wget -P output -c -r -np -k -L -p http://192.168.1.126/web/
# wget -P output -c -r -np -k -L -p http://192.168.1.126/video/
function bench_qzip_compression_ratio
{
    # Variables: raw vs. pcap & http vs. https & different data type
    # Workload: web, (OLTP queries,) video, (mixed)
    # Metrics: compression ratio
    local input_arr=(video-http.pcap video-https.pcap video.tar web-http.pcap web-https.pcap web.tar)
    local output_file=output/qzip_compression_ratio.csv

    printf "labels,compression ratio\n" >${output_file}
    for label in "${input_arr[@]}"; do
        echo -n "$label," >>${output_file}
        qzip -k input/$label 2>/dev/null | grep ratio | awk -F':' '{ print $2 }' | tr -d '\n' >>${output_file}
        echo >>${output_file}
    done
}


qzip_compression_level=(1 2 3 4)
# 4KB / 16KB / 64KB / 128KB / 512KB
qzip_compression_chunksz=(4096 16384 65536 131072 524288)
# for i in `seq -f %04g 0 999`; do cp web-http.pcap web-http$i.pcap; done
# tar -cf web-http-huge.pcap web-http-pcap-replicas
function bench_qzip_throughput_and_compression_ratio
{
    local input_file=input/web-http-huge.pcap
    local output_file_level=output/qzip_throughput_level.csv
    local output_file_chunk=output/qzip_throughput_chunk.csv

    printf "compression level,thoughput (Mbps),compression ratio\n" >${output_file_level}
    for level in "${qzip_compression_level[@]}"; do
        echo -n "$level," >>${output_file_level}
        qzip -L $level -k ${input_file} 2>/dev/null | \
            grep -E 'Throughput|ratio' | \
            awk -F':' '{ print $2 }' | \
            grep -Eo '[0-9]+([.][0-9]+)?' | \
            tr '\n' ',' >>${output_file_level}
        echo >>${output_file_level}
    done

    printf "chunk size (bytes),thoughput (Mbps),compression ratio\n" >${output_file_chunk}
    for chunksz in "${qzip_compression_chunksz[@]}"; do
        echo -n "$chunksz," >>${output_file_chunk}
        qzip -C $chunksz -k ${input_file} 2>/dev/null | \
            grep -E 'Throughput|ratio' | \
            awk -F':' '{ print $2 }' | \
            grep -Eo '[0-9]+([.][0-9]+)?' | \
            tr '\n' ',' >>${output_file_chunk}
        echo >>${output_file_chunk}
    done
}


function bench_cpu_consumption
{
    local input_file=input/web-http-huge.pcap
    local output_file_prefix=output/cpu_consumption

    pidstat -u 1 -e qzip -k ${input_file} >${output_file_prefix}_qzip.stdout && \
        printf "time,user,sys,total\n" >${output_file_prefix}_qzip.csv && \
        cat ${output_file_prefix}_qzip.stdout | grep qzip | grep -v Average | \
        awk -F' ' '{ print $1","$5","$6","$9 }' >>${output_file_prefix}_qzip.csv
    (test -f ${input_file}_0 || cp ${input_file}{,_0}) && \
        pidstat -u 1 -e gzip -f -1 ${input_file}_0 >${output_file_prefix}_gzip.stdout && \
        printf "time,user,sys,total\n" >${output_file_prefix}_gzip.csv && \
        cat ${output_file_prefix}_gzip.stdout | grep gzip | grep -v Average | \
        awk -F' ' '{ print $1","$5","$6","$9 }' >>${output_file_prefix}_gzip.csv
}


function bench_dpdk_pdump_qat
{
    # `dpdk-pdump-qat` runs in single process and synchronus mode.
    # Input: 10Gbps flow with web requests payload
    # Output: compressed pcap
    # Metircs: CPU consumption & disk IO & QAT TP & compression ratio
    echo "It's complicated and I haven't figure it out. ;)!"
}

case $1 in 
    cr)
        bench_qzip_compression_ratio
        ;;
    qtp)
        bench_qzip_throughput_and_compression_ratio
        ;;
    dio)
        bench_disk_IO_throughput
        ;;
    cpu)
        bench_cpu_consumption
        ;;
    pdump)
        bench_dpdk_pdump_qat
        ;;
    *)
        print_usage_then_die
esac


exit 0
