#!/usr/bin/python

import math
import copy

import networkx as nx
import networkx.algorithms as alg

#filename = "./rocketfuel_maps_cch/1239.r0.cch"
#filename = "./rocketfuel_maps_cch/2914.r0.cch"
#filename = "./rocketfuel_maps_cch/3356.r0.cch"
#filename = "./rocketfuel_maps_cch/3967.r0.cch"
#filename = "./rocketfuel_maps_cch/6461.r0.cch"
#filename = "./rocketfuel_maps_cch/6461.cch"
#filename = "./rocketfuel_maps_cch/7018.r0.cch"
#filename = "./rocketfuel_maps_cch/1755.cch"
#filename = "./rocketfuel_maps_cch/1755.r0.cch"


class PGComNet:
  def __init__(self, topo, bbs, gateways): 
    self.topo = topo
    self.bbs = bbs
    self.gateways = gateways

#if __name__ == "__main__":
#def makePGWAN(filename, nbus):
def makeWAN(filename):
  
   
    #print gateways`
    rG = nx.read_gml(filename, label='id')


    #bbs = rG.node
    #bbs = bbs.keys()
    #bbs.sort()
    #print bbs
    #assert(len(bbs) >= (nbus + 1))
    #assert(len(bbs) < (nbus + 1))
 

    # based on topo, construct the corresponding latency
    #latency = {}
    #for node, nbs in topo.iteritems():
    #  curName = uid2Name[node]
    
    # construct graphs based on topo
    '''
    nedge = 0
    for node , nbs in topo.iteritems():
        #if (node in busnode) or (node in bbs):
        for nb in nbs:
            nedge = nedge + 1
            rG.add_edge(node, nb)
    '''
  
    #print nedge 
    #print alg.is_connected(pgG)  
    #print alg.number_connected_components(pgG)
    #print "topology of the whole graph"
    comps = alg.connected_components(rG) 
    comps = sorted(comps, key=len, reverse=True )
    #for comp in comps:
        #print comp

    sRG = rG.subgraph(comps[0])
    
    # doing a clean up, removing the self loop edge in the graph
    alledges = sRG.edges()
    for e in alledges:
        if e[0] == e[1]:
            sRG.remove_edge(e[0], e[1])

    if alg.is_tree(sRG) == False:
        sRG = alg.minimum_spanning_tree(sRG)
        #print alg.is_tree(sRG) 

    return sRG
  
    ''' 
  print "topology of the power grid"
  print busnode
  pgG = rG.subgraph(busnode + bbs)
  print alg.number_connected_components(pgG)
  comps = alg.connected_components(pgG) 
  for comp in comps:
    print comp
    ''' 
    '''
  # using the biggest connected component to form WAN
  # have to first find how many gateways/access points are in this component
  # update bbs and gateways here
  pgB = []  # power grid backbone
  pgG = []  # power grid gateway access points
  for bb in bbs:
    if bb in comps[0]:
      pgB.append(bb)
  for gateway in gateways:
    if gateway in comps[0]:
      pgG.append(gateway)
  pgWAN = rG.subgraph(comps[0]) 
  comps = alg.connected_components(pgWAN)
  comps = sorted(comps, key=len, reverse=True )
  print "topology of the biggest connected component"
  for comp in comps:
    print comp

  ## one further step, let's find a small connected subgraph contains only
  #   sufficient nodes for substations, data aggregator, and a control center
  #pgG = pgG[0:(nbus + 1)]
  pgB = []
  for loop1 in range(0 , len(pgG)):
    for loop2 in range((loop1 + 1) , len(pgG)):
      sp = nx.shortest_path(pgWAN, pgG[loop1], pgG[loop2])
      for nn in sp:
        if nn not in pgB:
          pgB.append(nn)
  pgWAN = pgWAN.subgraph(pgB + pgG)
  # doing a clean up, removing the self loop edge in the graph
  alledges = pgWAN.edges()
  uniedges = []
  for e in alledges:
    if e[0] == e[1]:
      pgWAN.remove_edge(e[0], e[1])
  
  comps = alg.connected_components(pgWAN)
  comps = sorted(comps, key=len, reverse=True )
  print "topology of the power grid with loops"
  for comp in comps:
    print comp
  

  # removing the loops in the graph
  # using the control center as the root
  root = pgG[len(pgG) - 1 ]
  pgWANTree = nx.Graph()
  pgWANTree.add_nodes_from(pgG + pgB)
  visitNodes = []
  for loop1 in range(0, len(pgG) - 1):
    sp = nx.shortest_path(pgWAN, root, pgG[loop1])
    #print sp
    if sp[0] not in visitNodes:
      visitNodes.append(sp[0])
    for loop2 in range(1, len(sp)):
      e1 = sp[loop2-1]
      e2 = sp[loop2]
      if e2 not in visitNodes:
        visitNodes.append(e2)
        pgWANTree.add_edge(e1, e2)
  #print visitNodes
  if visitNodes != (pgG + pgB):
    print "Debug: further refine the graph"
    pgB = list(set(visitNodes) - set(pgG))
    pgWANTree = pgWANTree.subgraph(visitNodes)      
    
  comps = alg.connected_components(pgWANTree)
  comps = sorted(comps, key=len, reverse=True )
  print "topology of the power grid"
  print pgB
  print pgG
  for comp in comps:
    print comp     

  print alg.is_tree(pgWANTree) 
  result = PGComNet(pgWANTree, pgB, pgG)
  return result 
    '''
  
