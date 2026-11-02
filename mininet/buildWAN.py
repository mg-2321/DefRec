#!/usr/bin/python

import networkx as nx
import networkx.algorithms as alg

from mininet.net import Mininet
from mininet.node import Controller, RemoteController, OVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.topo import Topo
from mininet.link import TCLink

import os
import os.path
import time
import thread
#import matplotlib.pyplot as plt

#import matlab
#import matlab.engine
#from matpower_constant import *
import math
import random


import imp
#makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/SDNAC/WAN_simple.py")
makeWAN = imp.load_source("makeWAN", "/home/hugo/experiment/PowerSDN/Spoof/mininet/zooTopo.py")

dirname = '/home/hugo/experiment/InternetZoo/input/'
#filename = 'Dataxchange' # USA 6 switches
#filename = 'Abilene' # USA 11 switches
#filename = 'HurricaneElectric'     # global 24 switches
filename = 'Chinanet'     # 42 switches
#filename = 'Cesnet201006'     # cze republic 52 switches
#filename = 'Forthnet'     # 62 switches

controller='134.197.42.146'
n_host = 2 # number of hosts in each switch
ndevf = "/home/hugo/Dropbox/Public/ndev.txt"

INJECT = 0 # whether to perform injections or not
LATENCY = 1 #  whether set the latency in the graph
RELEASE = 1 # whether ready to run dnp3
n_phantom_node = 0  # number of phantom nodes 10% of ndevf
mean = 10
stadev = 5

if __name__ == "__main__":
    
   
    # got the network topo based on zooTopo
    rG = makeWAN.makeWAN(dirname + filename + '.gml')
    random.seed(1)


    # construct a networkx instance of a dumbbell topology
    #    s1----|  |    |  |----s6  
    #    s2----|s4|----|s5|----s7
    #    s3----|  |    |  |----s8
    #                      ----s9 (cc)
    '''
    b_switch = [4,5]
    e_switch = [1,2,3,6,7,8]
    c_switch = [9]
    rG = nx.Graph()
    rG.add_nodes_from(b_switch + e_switch + c_switch)
    rG.add_edge(4, 5)
    for left in range(1, 4): 
        rG.add_edge(left, 4)
    for right in range(6, 10):
        rG.add_edge(right, 5)
    '''

    # construct mininet of switch topology
    # evenly distribute network ndev nhosts on all switches
    nodes = rG.nodes()
    edges = rG.edges()

    if LATENCY == 1:
        edges_weights = {}; 

        for e in edges:
            if e not in edges_weights:
                edges_weights[e] = {}
            edges_weights[e]['weight'] = math.ceil( random.gauss(mean, stadev) )

        #print edges_weights
        nx.set_edge_attributes(rG, edges_weights)


    switch_handles = {}
    switch_names = {}
    host_handles = {}
    host_names = {}
    host_ips = {}
    topo = Topo()

    ndev=len(nodes)*n_host
    fo = open(ndevf, 'w')
    fo.write(filename + '\n')
    fo.write( str( ndev ) )
    fo.close()

   
    for n in nodes:
        temp = topo.addSwitch( "s{}".format(n) , dpid = '{}'.format(n) , mac = n)
        if n not in switch_names:
            switch_names[n] = temp
    
    for e in edges:
        if e[0] not in switch_names:
            print "source node is not created"
            break
        if e[1] not in switch_names:
            print "destination node is not created"
            break
        srcS = switch_names[e[0]]
        dstS = switch_names[e[1]]
        #linkopts = dict(bw=15, delay='{}ms'.format(pgCom.topo[e[0]][e[1]]['weight']))
        if LATENCY == 1:
            #print e[0], e[1]
            linkopts = dict(bw=10, delay='{}ms'.format(rG.edges[ e[0], e[1] ]['weight']))
            #linkopts = dict(bw=15, delay='2ms')
            topo.addLink(srcS, dstS, **linkopts)
        else:
            topo.addLink(srcS, dstS)
    
    # adding hosts
    # iterate each switch and add n_host in each switch
    
    host_d = {}  # number of hosts in each switches; indexed by e_switch id
    rem_hosts = range(1, (ndev+1));
    #rem_hosts = range(1, len(switch_names) * n_host + 1)
    #print rem_hosts
    i = 0
    #while len(rem_hosts) > 0:
    #for e in e_switch:
    for e in nodes:
        if e not in host_d:
            host_d[e] = []
        #print len(rem_hosts)
        #host_d[e].append(rem_hosts[0])
        #del rem_hosts[0]
        for loop2 in range(1, n_host + 1):
            #print i, rem_hosts[i]
            host_d[e].append(rem_hosts[i])
            i = i + 1;

    #print nodes.keys()
    #print host_d    
    for (e, hosts) in host_d.iteritems():
        for host in hosts:
            switch_h = switch_names[e]
            host_h = topo.addHost("h{}".format(host), ip='10.0.{}.{}'.format(e, host))
            host_names[host] = host_h
            host_ips[host] = '10.0.{}.{}'.format(e, host)
            if LATENCY == 1:
                linkopts = dict(bw=10, delay='{}ms'.format(mean))
                #linkopts = dict(bw=15, delay='2ms')
                #topo.addLink(switch_h, host_h, **linkopts)    
                topo.addLink(switch_h, host_h)
            else:
                topo.addLink(switch_h, host_h)
    
    # add the control center
    '''
    switch_h = switch_names[c_switch[0]]
    host_h = topo.addHost("h{}".format(ndev+1), ip='10.0.{}.{}'.format(c_switch[0], ndev+1))
    host_names[ndev+1] = host_h
    host_ips[ndev+1] = '10.0.{}.{}'.format(c_switch[0], ndev+1)
    topo.addLink(switch_h, host_h)
    '''
    p_host_d = {}  # number of hosts in each switches; indexed by e_switch id
    p_host_names = {}
    p_host_ips = {}
    p_host_handles = {}
    if INJECT == 1:
        # number of phantom nodes
        n_phantom_node = int( math.ceil(ndev / 10) )
        #phantom_switch_i = random.sample(range(1, len(nodes)), n_phantom_node)  # not including the switch with control center 
        for loop2 in range(1, n_phantom_node + 1):
            temp_i = random.randint(0, len(nodes) - 1) # not including the switch with control center
            if temp_i not in p_host_d:
                p_host_d[ temp_i ] = []
            
            p_host_d[ temp_i ].append(ndev + loop2)
        
        for (e, p_hosts) in p_host_d.iteritems():
            for p_host in p_hosts:
                switch_h = switch_names[e]
                p_host_h = topo.addHost("h{}".format(p_host), ip='10.0.{}.{}'.format(e, p_host))
                p_host_names[p_host] = p_host_h
                p_host_ips[p_host] = '10.0.{}.{}'.format(e, p_host) 
                topo.addLink(switch_h, p_host_h)

    
    # construct mininet topo
    #net = Mininet(topo, controller=None, switch=OVSSwitch)
    net = Mininet(topo, controller=None, switch=OVSSwitch, link=TCLink)
    #net = Mininet( controller=Controller, switch=OVSSwitch , link=TCLink)
    #c1 = net.addController( 'c1', controller=RemoteController, ip="127.0.0.1", port=6633 )
    c1 = net.addController( 'c1', controller=RemoteController, ip=controller, port=6633 )
    net.start()
    # after net is started; replaces all names with handles
    for (host_id, host_name) in host_names.iteritems():
        host_handles[host_id] = net.get(host_name)
    for (switch_id, switch_name) in switch_names.iteritems():
        switch_handles[switch_id] = net.get(switch_name)

    if INJECT == 1:
        for (p_host_id, p_host_name) in p_host_names.iteritems():
            p_host_handles[p_host_id] = net.get(p_host_name)
    
    ###### construct flow rules manually
    for (switch_id, switch_name) in switch_names.iteritems():
        cmd = "ovs-ofctl add-flow s{} dl_type=0x0806,action=all".format(switch_id) 
        switch_handles[switch_id].cmd(cmd)
        #cmd = "ovs-ofctl add-flow s{} dl_type=0x0800,action=all".format(switch_id) 
        #switch_handles[switch_id].cmd(cmd)


      
    ######## running DNP3 applications here
    if RELEASE == 1:
        # running outstation; for device of transmission line assign f_bus as its
        
        for loop1 in range(1, (ndev+1)):
            # last host is control center
            if loop1 < ndev:
                runCmd = 'outstationdemo {} &> ./log/outstation{}-out.txt &'.format(loop1, loop1)
                #runCmd = 'outstationdemo {} &'.format(loop1)
                host_h = host_handles[loop1]
                pid = host_h.cmd(runCmd)
        
        # running outstationdemo in phantom nodes
        
        if INJECT == 1:
            for loop1 in range(ndev + 1, ndev + n_phantom_node + 1):
                #runCmd = 'outstationdemo {} &'.format(loop1)
                runCmd = 'outstationdemo {} &> ./log/poutstation{}-out.txt &'.format(loop1, loop1)
                p_host_h = p_host_handles[loop1]
                pid = p_host_h.cmd(runCmd)
        
        # running tcpdump command in control center
        time.sleep(5)
        cc_h = host_handles[ndev]
        if INJECT == 1:
            runCmd = 'tcpdump -i {}-eth0 -s 65535 -w ./log/{}-spoof.pcap &'.format(host_names[ndev], filename)
        else:
            runCmd = 'tcpdump -i {}-eth0 -s 65535 -w ./log/{}-base.pcap &'.format(host_names[ndev], filename)
        cc_h.cmd(runCmd)

        #running masterdemo
         
        time.sleep(30)
        for loop1 in range(1, ndev):
            runCmd = 'masterdemo ' + host_ips[loop1] + ' 20000 &> ./log/cc-h{}-out.txt &'.format(loop1)
            host_h = host_handles[ndev]
            pid = host_h.cmd(runCmd)
        if INJECT == 1:
            for loop1 in range(ndev + 1, ndev + n_phantom_node + 1):
                runCmd = 'masterdemo ' + p_host_ips[loop1] + ' 20000 &> ./log/cc-p{}-out.txt &'.format(loop1)
                host_h = host_handles[ndev]
                pid = host_h.cmd(runCmd)

        
       
    CLI(net)
    net.stop()    
