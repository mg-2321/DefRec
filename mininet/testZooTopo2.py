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
#filename = 'Forthnet'     # 62 switches
#filename = 'Belnet2003'

#files = ('Arpanet196912', 'Arpanet19706', 'Arpanet19719', 'Arpanet19723', 'Arpanet19728');
#files = ('Belnet2003', 'Belnet2004', 'Belnet2005', 'Belnet2006', 'Belnet2007', 'Belnet2008', 'Belnet2009', 'Belnet2010')
#files = ('Cesnet1993', 'Cesnet1997', 'Cesnet1999', 'Cesnet2001', 'Cesnet200304', 'Cesnet200511', 'Cesnet200603', 'Cesnet200706', 'Cesnet201006')
#files = ('Garr199901', 'Garr199904', 'Garr199905', 'Garr200109', 'Garr200112', 'Garr200212', 'Garr200404', 'Garr200902', 'Garr200908', 'Garr200909', 'Garr200912', 'Garr201001', 'Garr201003', 'Garr201004', 'Garr201005', 'Garr201007', 'Garr201008', 'Garr201010', 'Garr201012', 'Garr201101', 'Garr201102', 'Garr201103', 'Garr201104', 'Garr201105', 'Garr201107', 'Garr201108', 'Garr201109', 'Garr201110', 'Garr201111', 'Garr201112', 'Garr201201')
#files = ('Geant2001', 'Geant2009', 'Geant2010', 'Geant2012')
#files = ('Kentman200507', 'Kentman200508', 'Kentman200704', 'Kentman200802', 'Kentman201101')
#files = ('Nordu1989', 'Nordu1997', 'Nordu2005', 'Nordu2010')
files = ('Renater1999', 'Renater2001', 'Renater2004', 'Renater2006', 'Renater2008','Renater2010')

mean=10
stadev=5

if __name__ == "__main__":
    
    for loop1 in range(0, len(files)):
        filename = files[loop1]
        rG = makeWAN.makeWAN(dirname + filename + '.gml')
        
        print '% {}: {}, {}'.format(filename, len(rG.nodes()), len(rG.edges())) 
