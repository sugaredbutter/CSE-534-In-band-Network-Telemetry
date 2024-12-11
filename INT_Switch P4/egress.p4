
/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    action forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;


    }
    #define PKT_INSTANCE_TYPE_INGRESS_CLONE 1

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

   

    bit<16> total_len = 0;
    
    apply { 
        log_msg("====TYPE OF PACKET = {}", {standard_metadata.instance_type});
        if(hdr.ipv4.isValid()) {

            //Investigating implementing MTU consideration but ran out of time. No functionality besides printing
            total_len = hdr.ipv4.totalLen + 4 + 4 + 2 + (bit<16>)( hdr.INT_shim.length * (bit<8>)hdr.INT_header.hopML * 4);
            log_msg("====LENGTH OF PACKET = {}", {total_len});
            //if(total_len < 1400)  

            //INT header exists
            if (hdr.INT_header.isValid()) {
                //HopCount > 0 and not the sink (D == 1 means strip data)
                if(hdr.INT_header.remHopCount > 0 && hdr.INT_header.D != 1)
                {
                    //Append Data and increase shim.length by 1
                    hdr.INT_shim.length =  hdr.INT_shim.length + 1;

                    //If bitmap.attribute == 1, setValid the header and add data to it.
                    if(hdr.INT_bitmap.nodeID == 1)
                    {
                        hdr.nodeID.setValid();
                        hdr.nodeID.nodeID = 1;
                    }
                    if(hdr.INT_bitmap.lvl1_ingress_egress_ID == 1)
                    {
                        hdr.lvl1_ID.setValid();
                        hdr.lvl1_ID.ingressID = (bit<16>)standard_metadata.ingress_port;
                        hdr.lvl1_ID.egressID = (bit<16>)standard_metadata.egress_port;
                    }
                    if(hdr.INT_bitmap.hopLatency == 1)
                    {
                        hdr.hop_latency.setValid();
                        hdr.hop_latency.hop_latency = (bit<32>)(standard_metadata.egress_global_timestamp - standard_metadata.ingress_global_timestamp);
                    }
                    if(hdr.INT_bitmap.queueInfo == 1)
                    {
                        hdr.queueInfo.setValid();
                        hdr.queueInfo.queueID = 0; 
                        hdr.queueInfo.queueOccupancy = (bit<24>)standard_metadata.enq_qdepth;
                    }
    
                    if(hdr.INT_bitmap.ingressTS == 1)
                    {
                        hdr.ingressTS.setValid();
                        hdr.ingressTS.ingressTS = (bit<64>)standard_metadata.ingress_global_timestamp;
                    }
                    if(hdr.INT_bitmap.egressTS == 1)
                    {
                        hdr.egressTS.setValid();
                        hdr.egressTS.egressTS = (bit<64>)standard_metadata.egress_global_timestamp;
                    }
                    if(hdr.INT_bitmap.lvl2_ingress_egress_ID == 1)
                    {
                        hdr.lvl2_ID.setValid();
                        hdr.lvl2_ID.ingressID = 0;
                        hdr.lvl2_ID.egressID = 0;
                    }
                    if(hdr.INT_bitmap.egressTx == 1)
                    {
                        hdr.egressTX.setValid();
                        hdr.egressTX.egressTX = 0;
                        
                    }
                    if(hdr.INT_bitmap.bufferInfo == 1)
                    {
                        hdr.bufferInfo.setValid();
                        hdr.bufferInfo.bufferID = 0;
                        hdr.bufferInfo.bufferOcc = 0;
                    }
                    hdr.INT_header.remHopCount =  hdr.INT_header.remHopCount - 1; 
                }
            }
            //No INT header exists
            else
            {
                //Shim
                hdr.INT_shim.setValid();
                hdr.INT_shim.type = 5;
                hdr.INT_shim.NPT = 0;
                hdr.INT_shim.rsvd = 0;
                hdr.INT_shim.length = 1;
                hdr.INT_shim.etc = (bit<16>)hdr.ipv4.protocol;

                //Header
                hdr.INT_header.setValid();
                hdr.INT_header.Ver = 2;
                hdr.INT_header.D = 0;
                hdr.INT_header.E = 0;
                hdr.INT_header.M = 0;
                hdr.INT_header.R = 0;
                hdr.INT_header.hopML = 0;
                hdr.INT_header.remHopCount = 3; 

                //Bitmap 
                hdr.INT_bitmap.setValid();
                hdr.INT_bitmap.nodeID = 1;
                hdr.INT_bitmap.lvl1_ingress_egress_ID = 1;
                hdr.INT_bitmap.hopLatency = 1;
                hdr.INT_bitmap.queueInfo = 1;
                hdr.INT_bitmap.ingressTS = 1;
                hdr.INT_bitmap.egressTS = 1;

                //No functionality currently
                hdr.INT_bitmap.lvl2_ingress_egress_ID = 0;
                hdr.INT_bitmap.egressTx = 0;
                hdr.INT_bitmap.bufferInfo = 0;
                hdr.INT_bitmap.rsvd = 0;
                hdr.INT_bitmap.checksumComplement = 0;

                //If bitmap.attribute == 1, setValid the header and add data to it.
                if(hdr.INT_bitmap.nodeID == 1)
                {
                    hdr.nodeID.setValid();
                    hdr.nodeID.nodeID = 1;
    
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                    
                    
                }
                if(hdr.INT_bitmap.lvl1_ingress_egress_ID == 1)
                {
                    hdr.lvl1_ID.setValid();
                    hdr.lvl1_ID.ingressID = (bit<16>)standard_metadata.ingress_port;
                    hdr.lvl1_ID.egressID = (bit<16>)standard_metadata.egress_port;

                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                    
                   
                }
                if(hdr.INT_bitmap.hopLatency == 1)
                {
                    hdr.hop_latency.setValid();
                    hdr.hop_latency.hop_latency = (bit<32>)(standard_metadata.egress_global_timestamp - standard_metadata.ingress_global_timestamp);
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                    
                    
                }
                if(hdr.INT_bitmap.queueInfo == 1)
                {
                    hdr.queueInfo.setValid();
                    hdr.queueInfo.queueID = 0; 
                    hdr.queueInfo.queueOccupancy = (bit<24>)standard_metadata.enq_qdepth;   //Can also be deq_qdepth which collects q depth when packet exits queue
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                
                }

                if(hdr.INT_bitmap.ingressTS == 1)
                {
                    hdr.ingressTS.setValid();
                    hdr.ingressTS.ingressTS = (bit<64>)standard_metadata.ingress_global_timestamp;
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 2;
                }
                if(hdr.INT_bitmap.egressTS == 1)
                {
                    hdr.egressTS.setValid();
                    hdr.egressTS.egressTS = (bit<64>)standard_metadata.egress_global_timestamp;
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 2;
                }
                if(hdr.INT_bitmap.lvl2_ingress_egress_ID == 1)
                {
                    hdr.lvl2_ID.setValid();
                    hdr.lvl2_ID.ingressID = 0;
                    hdr.lvl2_ID.egressID = 0;
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 2;                    
                }
                if(hdr.INT_bitmap.egressTx == 1)
                {
                    hdr.egressTX.setValid();
                    hdr.egressTX.egressTX = 0;
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                    
                }
                if(hdr.INT_bitmap.bufferInfo == 1)
                {
                    hdr.bufferInfo.setValid();
                    hdr.bufferInfo.bufferID = 0;
                    hdr.bufferInfo.bufferOcc = 0;
                    hdr.INT_header.hopML = hdr.INT_header.hopML + 1;                        
                }
            }
            if (hdr.INT_header.isValid())
            {
                if (!hdr.dummy_udp.isValid())
                {
                    hdr.dummy_udp.setValid();
                    hdr.dummy_udp.srcPort = 0;
                    hdr.dummy_udp.dstPort = 1234;
                    hdr.dummy_udp.length = 0;                
                    hdr.dummy_udp.checksum = 0;      
                    hdr.ipv4.protocol = 17;
    
                }
            }
        }

        //If the packet has D flag set and not a clone, then invalidate INT stuff so it is the original packet
        if(hdr.ipv4.isValid() && hdr.INT_header.isValid() && hdr.INT_header.D == 1 && standard_metadata.instance_type != PKT_INSTANCE_TYPE_INGRESS_CLONE)
        {
            hdr.ipv4.protocol = (bit<8>)hdr.INT_shim.etc;
            hdr.dummy_udp.setInvalid();
            hdr.INT_shim.setInvalid();
            hdr.INT_header.setInvalid();
            hdr.INT_bitmap.setInvalid();
            hdr.INT_payload.setInvalid();
            hdr.nodeID.setInvalid();
            hdr.lvl1_ID.setInvalid();
            hdr.hop_latency.setInvalid();
            hdr.queueInfo.setInvalid();
            hdr.ingressTS.setInvalid();
            hdr.egressTS.setInvalid();
            hdr.lvl2_ID.setInvalid();
            hdr.egressTX.setInvalid();
            hdr.bufferInfo.setInvalid();

        }
        //If it is a cloned packet, then forward it to INT collector
        if(hdr.ipv4.isValid() && standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_CLONE) {
            hdr.ipv4.dstAddr = 0xC0A80502;
            if(ipv4_exact.apply().miss) {
                ipv4_lpm.apply();
            }
        }
    }
}