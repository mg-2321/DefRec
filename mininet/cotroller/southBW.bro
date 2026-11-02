
#redef tcp_content_delivery_ports_orig +={ [6633/tcp] = T };
#redef tcp_content_delivery_ports_resp +={ [6633/tcp] = T };
redef tcp_content_deliver_all_orig = T;
redef tcp_content_deliver_all_resp = T;

const cc_ip : addr = 192.171.20.100;  ## controller at the cc
#const cc_host : addr = 10.10.14.3;
#const cc_ip : addr = 199.109.64.59;
#const cc_host : addr = 10.10.9.3;
const cc_host : addr = 10.10.38.3;

const OFP_HEADER_SIZE : count = 8; 
const OFP_PI_SIZE : count = 10;
const OFP_PO_SIZE : count = 8;
const OFP_ETH_HEADER : count = 14;
const OFP_IP_HEADER : count = 20;
const OFP_TCP_HEADER : count = 32; 

global packet_in : table[addr] of time;
global pi_size : table[addr] of double;
#global of_latency : vector of double;
#global latency_index : count = 0;
#global of_size : vector of double;
#global size_index : count = 0;
global of_bw_on : table[addr] of vector of double;
global of_bw_off : table[addr] of vector of double;
#global bw_index : count = 0;
global total_pi : count = 0;

global southBW_log = open_log_file("southBW");

event tcp_contents(c: connection, is_orig: bool, seq: count, contents: string)
    {
    #print "tcp contents of", network_time(), c$id$orig_h, c$id$orig_p, c$id$resp_h, c$id$resp_p, is_orig, |contents|;
    local of_version : count = 0; 
    local of_fc : count = 0;
    local of_interval : double;
    local of_eth_header : string;
    local of_eth_type : count = 0;
    local of_ip_header : string;
    local of_srcip : addr;
    local of_dstip : addr;
    local of_acts_len : count = 0;
    local of_ip_total_len : count = 0;
    local of_tcp_header_len : count = 0;
    local of_tcp_data_len : count = 0;
    
   
    if (( c$id$orig_h == cc_ip || c$id$resp_h == cc_ip ) && (c$id$orig_p == 6633/tcp || c$id$resp_p == 6633/tcp) && |contents| > 2)
        {
        #print "tcp contents of", network_time(), c$id$orig_h, c$id$orig_p, c$id$resp_h, c$id$resp_p, is_orig, |contents|, contents[0], contents[1];
        of_version = bytestring_to_count(sub_bytes(contents, 0, 1), T);
        #of_fc = bytestring_to_count(sub_bytes(contents[1], 0, 1), T);
        of_fc = bytestring_to_count(sub_bytes(contents, 2, 1), T);
        #print "fuck", of_fc, contents[0], contents[1];
         
        if ( of_version == 1 )
            {
            #print "openflow", of_version, of_fc;
            if (of_fc == 0x0a)
                {
                #print "packet in";
                #packet_in = network_time();
                #pi_size = |contents| + 14 + 20 + 32;
                of_eth_header = sub_bytes(contents, OFP_HEADER_SIZE + OFP_PI_SIZE + 1,  OFP_ETH_HEADER);
                of_eth_type = bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PI_SIZE + 12 + 1, 2));
                
                #print "packet in ", network_time(), of_eth_header, of_eth_type;
                if (of_eth_type == 0x0800) # ipv4
                    {
                    of_ip_header = sub_bytes(contents, OFP_HEADER_SIZE + OFP_PI_SIZE + OFP_ETH_HEADER + 1, OFP_IP_HEADER);
                    of_srcip = count_to_v4_addr(bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PI_SIZE + OFP_ETH_HEADER + 12 + 1, 4)));
                    of_dstip = count_to_v4_addr(bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PI_SIZE + OFP_ETH_HEADER + 16 + 1, 4)));
                    if (of_dstip == cc_host)
                        {
                        packet_in[of_srcip] = network_time();
                        pi_size[of_srcip] = |contents|;
                        if ( of_srcip !in of_bw_on )
                            of_bw_on[of_srcip] = vector();
                        if ( of_srcip !in of_bw_off )
                            of_bw_off[of_srcip] = vector();
                        total_pi = total_pi + 1;
                        #print "openflow packet in ", network_time(), of_srcip, of_dstip; 
                        }
                    }
                
                }
            if (of_fc == 0x0d)
                {
                #print "packet out";
                of_acts_len = bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE - 2 + 1,  2));
                of_eth_header = sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + 1,  OFP_ETH_HEADER);
                of_eth_type = bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + 12 + 1, 2));
                
                #print "openflow packet out ", network_time(), of_eth_header, of_eth_type;
                if (of_eth_type == 0x0800) # ipv4
                    {
                    of_ip_header = sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + OFP_ETH_HEADER + 1, OFP_IP_HEADER);
                    of_srcip = count_to_v4_addr(bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + OFP_ETH_HEADER + 12 + 1, 4)));
                    of_dstip = count_to_v4_addr(bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + OFP_ETH_HEADER + 16 + 1, 4)));
                    if (of_dstip == cc_host)
                        {
                        if ( of_srcip in packet_in )
                            {
                            of_interval = interval_to_double(network_time() - packet_in[of_srcip]);
                            of_ip_total_len = bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + OFP_ETH_HEADER + 2 + 1, 2), F);
                            of_tcp_header_len = bytestring_to_count(sub_bytes(contents, OFP_HEADER_SIZE + OFP_PO_SIZE + of_acts_len + OFP_ETH_HEADER + OFP_IP_HEADER + 12 + 1, 1));
                            of_tcp_data_len = of_ip_total_len - OFP_IP_HEADER - of_tcp_header_len / 16 * 4;                                    
                            if (of_tcp_data_len == 68 && of_interval > 0)
                                {
                                #print "decoy ";
                                #print "openflow packet out ", network_time(), of_srcip, of_dstip, packet_in[of_srcip];
                                #print contents;
                                of_bw_off[of_srcip][|of_bw_off[of_srcip]|] = pi_size[of_srcip] / of_interval;
                                }
                            if (of_tcp_data_len == 85 && of_interval > 0)
                                {
                                #print "real ";
                                of_bw_on[of_srcip][|of_bw_on[of_srcip]|] = pi_size[of_srcip] / of_interval;
                                }
                            }
                        #print "openflow packet out ", network_time(), of_srcip, of_dstip;
                        }
                    }


                
                }
            }

        }
    }

event bro_done()
    {
    print total_pi;
    #print southBW_log, of_bw;
    for (k in of_bw_on)
        {
        print southBW_log, fmt("%s", k);
        print southBW_log, of_bw_on[k];
        print southBW_log, of_bw_off[k];
        } 
    }
