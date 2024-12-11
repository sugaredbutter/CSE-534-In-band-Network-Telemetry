/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/
#include <v1model.p4>
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
   
    action forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;


    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr:lpm;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    table ipv4_exact {
        key = {
            hdr.ipv4.dstAddr:exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }
    apply {
        if(hdr.ipv4.isValid()) {
            if(ipv4_exact.apply().miss) {
                ipv4_lpm.apply();
            }
            else
            {
                //Clone if exact match (indicates next hop is destination)
                if(hdr.INT_header.isValid())
                {
                    clone_preserving_field_list(CloneType.I2E, 1, 0);
                    hdr.INT_header.D = 1;
                }
            }
        }

        
    }
}