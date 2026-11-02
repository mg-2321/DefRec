#!/usr/bin/python

import networkx as nx
import networkx.algorithms as alg

#import numpy
import random
import math

import imp
#makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/SDNAC/WAN_simple.py")
makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/Spoof/mininet/zooTopo.py")

dirname = '/home/hugo/experiment/InternetZoo/input/'
#filename = 'Quest'
#filename = 'Dataxchange'  # USA 6 switches
#filename = 'Nsfnet'     # 13 switches
#filename = 'Abilene'     # usa 11 switches
#filename = 'Bbnplanet'     # 27 switches
#filename = 'HurricaneElectric'     # global 24 switches
#filename = 'Chinanet'     # 42 switches
#filename = 'Cesnet201006'     # cze republic 52 switches
filename = 'Forthnet'     # 62 switches


mean=10
stadev=5

if __name__ == "__main__":
    
    rG = makeWAN.makeWAN(dirname + filename + '.gml')
    random.seed(1)
    

    print 'the network has {} switches {} links '.format(len(rG.nodes()), len(rG.edges()))

    print rG.edges()

    edges = rG.edges()
    nodes = rG.nodes()

    print nodes
    print nodes[0]

    edges_weights = {}; 

    for e in edges:
        if e not in edges_weights:
            edges_weights[e] = {}
        
        edges_weights[e]['weight'] = math.ceil( random.gauss(mean, stadev) )
    

    print edges_weights
    nx.set_edge_attributes(rG, edges_weights)
    
    
    #print rG.edges[0,5]['weight']

