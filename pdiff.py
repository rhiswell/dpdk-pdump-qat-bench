#!venv/bin/python3

from scapy.all import rdpcap, raw
from hashlib import md5
import click
import numpy as np
import matplotlib.pyplot as plt


pkt = lambda fpath: rdpcap(fpath)


def plot(base_event, filtered_event):
    plt.eventplot([base_event, filtered_event],
            colors=[[0, 1, 0], [1, 0, 0]],
            lineoffsets=[0, 0])
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

    for idx, pkt in enumerate(cap1):
        hval = md5(raw(pkt)).hexdigest()
        d[hval] = -1

    filtered_idx = list(filter(lambda x: x >= 0, d.values()))

    plot(range(1, len(cap0)+1), filtered_idx)


if __name__ == "__main__":
    main()
