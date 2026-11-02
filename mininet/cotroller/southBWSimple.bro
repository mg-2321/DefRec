
#redef tcp_content_delivery_ports_orig +={ [6633/tcp] = T };
#redef tcp_content_delivery_ports_resp +={ [6633/tcp] = T };
redef tcp_content_deliver_all_orig = T;
redef tcp_content_deliver_all_resp = T;

const cc_ip : addr = 134.197.42.146;  ## controller at the cc
#const cc_host : addr = 10.10.14.3;
#const cc_ip : addr = 199.109.64.59;
#const cc_host : addr = 10.10.9.3;
const mininet_ip : addr = 134.197.40.237;

const OFP_HEADER_SIZE : count = 8; 
const OFP_PI_SIZE : count = 10;
const OFP_PO_SIZE : count = 8;
const OFP_ETH_HEADER : count = 14;
const OFP_IP_HEADER : count = 20;
const OFP_TCP_HEADER : count = 32; 

#global packet_in : table[addr] of time;
#global pi_size : table[addr] of double;
global packe_in : time;
global pi_all_size: double = 0.0;
global pi_app_size: double = 0.0;
#global of_latency : vector of double;
#global latency_index : count = 0;
#global of_size : vector of double;
#global size_index : count = 0;
#global of_bw_on : table[addr] of vector of double;
#global of_bw_off : table[addr] of vector of double;
global of_tp : vector of double;
global of_gp : vector of double;
global of_latency : vector of double;
#global bw_index : count = 0;
global total_pi : count = 0;

global of_last : time;
global good_size : double = 0.0;

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
    
   
    #if ( c$id$orig_h == cc_ip &&  c$id$resp_h == cc_host && c$id$orig_p == 6633/tcp && |contents| > 2)
    #if ( c$id$orig_h == mininet_ip &&  c$id$resp_h == cc_ip && is_orig == F)
    if ( c$id$orig_h == mininet_ip &&  c$id$resp_h == cc_ip)
        {
        #print "open fl
        of_version = bytestring_to_count(sub_bytes(contents, 0, 1), T);
        of_fc = bytestring_to_count(sub_bytes(contents, 2, 1), T);

        if ( of_version == 0x04 )
            {
            #print "openflow", of_version, of_fc;
            if (of_fc == 0x0a)
                {
                # print "packet in"
                packet_in = network_time();
                pi_app_size = |contents|;
                pi_all_size = pi_app_size + 14 + 20 + 32;
                total_pi = total_pi + 1;
                }
            }
            if (of_fc == 0x0d)
                {
                of_interval = interval_to_double(network_time() - packet_in);
                of_latency[ |of_latency| ] = of_interval;
                of_tp[ |of_tp| ] = pi_all_size / of_interval;
                of_gp[ |of_gp| ] = pi_app_size / of_interval;
                
                }

        }
    }

event bro_done()
    {
    print total_pi;
    print southBW_log, of_bw;

    print southBW_log, of_gp;
    print southBW_log, of_tp;
    print southBW_log, of_latency;
    }
