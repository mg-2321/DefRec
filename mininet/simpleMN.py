#!/usr/bin/python

from mininet.net import Mininet
from mininet.node import Controller, RemoteController, OVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.topo import Topo

#controller='134.197.42.146'
controller='127.0.0.1'
ndevf = "/home/hugo/Dropbox/Public/ndev.txt"

def int2dpid( dpid ):
   try:
      dpid = hex( dpid )[ 2: ]
      dpid = '0' * ( 16 - len( dpid ) ) + dpid
      return dpid
   except IndexError:
      raise Exception( 'Unable to derive default datapath ID - '
                       'please either specify a dpid or use a '
		       'canonical switch name such as s23.' )
def int2mac( input ):
    result = ''
    r2 = input
    
    #while r2 > 0:
    for loop1 in range(1, 13):
        r1 = r2 % 16
        r1p = hex(r1)
        result = str(r1p[len(r1p)-1]) + result
        r2 = r2 / 16
        if (loop1 % 2) == 0 and (loop1 < 12) :
            result = ':' + result

    return result

if __name__ == "__main__":


    # test int2mac
    #for loop0 in range(1,300):
    #    print int2mac(loop0)
    

    fo = open(ndevf, 'w')
    fo.write('test\n')
    fo.write( str( 2 ) )
    fo.close()

    topo = Topo()

    temp = topo.addSwitch('s1', dpid = '1', mac = 1)
    #print int2dpid(1)
    temp = topo.addSwitch('s2', dpid = int2dpid(2), mac = 2)
    #temp = topo.addSwitch('s3', mac = 3)
    topo.addHost('h3', ip='10.0.0.3', mac=int2mac(1))
    topo.addHost('h1', ip='10.0.0.1', mac=int2mac(2))
    topo.addHost('h2', ip='10.0.0.2', mac=int2mac(3))
    topo.addLink('s1', 'h3', 2, 1)
    topo.addLink('s2', 'h1', 3, 1)
    topo.addLink('s2', 'h2', 4, 1)
    topo.addLink('s1', 's2', 3, 5)
    #topo.addLink('s2', 's3')

    #net = Mininet(topo, controller=None, switch=OVSSwitch)
    net = Mininet(topo, controller=Controller, switch=OVSSwitch)
    #c1 = net.addController( 'c1', controller=RemoteController, ip="127.0.0.1", port=6633 )
    #c1 = net.addController( 'c1', controller=RemoteController, ip="134.197.40.237", port=6633 )
    #c1 = net.addController( 'c1', controller=RemoteController, ip="134.197.42.146", port=6633 )
    c1 = net.addController( 'c1', controller=Controller )

    net.start()
    s1 = net.get('s1')
    s2 = net.get('s2')
    h1 = net.get('h1')
    h2 = net.get('h2')
    h3 = net.get('h3')
    #s3 = net.get('s3')


    ## these commands won work for onos controller
    #    as onos controller will remove all rules in switches by default
    '''
    cmd = 'ovs-ofctl add-flow s1 dl_type=0x0806,action=all'
    s1.cmd(cmd)
    cmd = 'ovs-ofctl add-flow s2 dl_type=0x0806,action=all'
    s2.cmd(cmd)
    #s3.cmd(cmd)
    '''

    '''
    #cmd = 'ovs-ofctl add-flow s1 dl_type=0x0800,action=all'
    cmd = 'ovs-ofctl add-flow s1 dl_type=0x0800,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02,action=output:s1-eth3'
    s1.cmd(cmd)
    cmd = 'ovs-ofctl add-flow s1 dl_type=0x0800,dl_src=00:00:00:00:00:02,dl_dst=00:00:00:00:00:01,action=output:s1-eth2'
    s1.cmd(cmd)
    #cmd = 'ovs-ofctl add-flow s2 dl_type=0x0800,action=all'
    cmd = 'ovs-ofctl add-flow s2 dl_type=0x0800,dl_src=00:00:00:00:00:02,dl_dst=00:00:00:00:00:01,action=output:s2-eth5'
    s2.cmd(cmd)
    cmd = 'ovs-ofctl add-flow s2 dl_type=0x0800,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02,action=output:s2-eth3'
    s2.cmd(cmd)
    '''

    # using h1 as the control center
    ##cmd = 'outstationdemo 2 &'
    #h2.cmd(cmd)
    ##cmd = 'outstationdemo 3 &'
    #h3.cmd(cmd)

    ##cmd = 'masterdemo 10.0.2.2 20000 &'
    #h1.cmd(cmd)
    ##cmd = 'masterdemo 10.0.2.3 20000 &'
    #h1.cmd(cmd)

    CLI(net)

    net.stop()
    
