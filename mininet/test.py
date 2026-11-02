#!/usr/bin/python


import glob, os
import networkx as nx

import imp
#makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/SDNAC/WAN_simple.py")
makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/Spoof/mininet/zooTopo.py")

dirname = '/home/hugo/experiment/InternetZoo/input/'
filename = 'Quest.gml'


if __name__ == '__main__':

    makeWAN.makeWAN(dirname + filename)
