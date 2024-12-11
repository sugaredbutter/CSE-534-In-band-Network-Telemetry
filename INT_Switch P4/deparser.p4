
/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.dummy_udp);    
        packet.emit(hdr.INT_shim);
        packet.emit(hdr.INT_header);
        packet.emit(hdr.INT_bitmap);
        packet.emit(hdr.nodeID);
        packet.emit(hdr.lvl1_ID);
        packet.emit(hdr.hop_latency);
        packet.emit(hdr.queueInfo);
        packet.emit(hdr.ingressTS);
        packet.emit(hdr.egressTS);
        packet.emit(hdr.lvl2_ID);
        packet.emit(hdr.egressTX);
        packet.emit(hdr.bufferInfo);
        packet.emit(hdr.INT_payload);
        packet.emit(hdr.udp);    
        
    }
}
