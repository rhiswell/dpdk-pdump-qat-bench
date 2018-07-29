#!venv/bin/python3

from scapy.all import rdpcap, raw
from hashlib import md5
import click
import numpy as np
import matplotlib.pyplot as plt


pkts = lambda fpath: rdpcap(fpath)


def plot(base, filtered, rate_damaged_pkts, rate_lost_pkts):
    plt.eventplot([base, filtered],
            colors=[[0, 1, 0], [1, 0, 0]],
            lineoffsets=[0, 0])
    plt.text(0, 1, r'$rate\_of\_lost\_packets={},\ rate\_of\_damaged\_packets={}$'
            .format(round(rate_lost_pkts, 2), round(rate_damaged_pkts, 2)))
    plt.show()


@click.command()
@click.argument("pcap0")
@click.argument("pcap1")
def main(pcap0, pcap1):
    cap0 = pkts(pcap0)
    cap1 = pkts(pcap1)

    d = dict()
    for idx, pkt in enumerate(cap0):
        hval = md5(raw(pkt)).hexdigest()
        d[hval] = idx

    damaged_pkts = 0
    for _, pkt in enumerate(cap1):
        hval = md5(raw(pkt)).hexdigest()
        if hval in d:
            d[hval] = -1
        else:
            damaged_pkts += 1

    # Filter out indices of lost or damaged packets
    idx_of_lost_or_damaged_pkts = list(filter(lambda x: x >= 0, d.values()))

    total_sent_pkts = len(cap0)
    total_recv_pkts = len(cap1)
    total_recv_pkts_no_damaged = total_recv_pkts - damaged_pkts
    assert(total_recv_pkts_no_damaged == (total_sent_pkts - len(idx_of_lost_or_damaged_pkts)))

    rate_damaged_pkts = damaged_pkts / total_sent_pkts
    rate_lost_pkts = (total_sent_pkts - total_recv_pkts) / total_sent_pkts

    #print("Rate of damaged packets: {}".format(round(rate_damaged_pkts, 2)))
    #print("Rate of lost packets: {}".format(round(rate_lost_pkts, 2)))

    plot(range(1, total_sent_pkts+1), idx_of_lost_or_damaged_pkts, rate_damaged_pkts, rate_lost_pkts)


if __name__ == "__main__":
    main()
