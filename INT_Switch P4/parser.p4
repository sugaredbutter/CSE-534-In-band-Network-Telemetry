#include "headers.p4"

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    bit<1> int_after = 0;
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: accept; // 6 indicates TCP (NO INT SINCE NO DUMMY UDP)
            17: parse_udp; //Maybe INT, check port is 1234
            default: accept;
        }
    }


    state parse_udp {
        packet.extract(hdr.udp);
        if (hdr.udp.dstPort == 1234) {    // Check if destination port matches INT port set
            hdr.dummy_udp = hdr.udp;
            hdr.udp.setInvalid();
            int_after = 1;
        } 
        transition select(int_after) {
            1       : parse_int;
            default: accept;
        }
    }

    state parse_int {
        packet.extract(hdr.INT_shim);
        packet.extract(hdr.INT_header);
        packet.extract(hdr.INT_bitmap);
        transition parse_int_payload;
    }

    state parse_int_payload {
        //Parse existing telemetry data from previous switches.
        //shim.length = # switches we've collected data from (not including this one yet) and hopML gives us length added per hop.
        packet.extract( hdr.INT_payload, (bit<32>)( (bit<32>)hdr.INT_shim.length * (bit<32>)hdr.INT_header.hopML * 4 * 8 ) );
        transition accept;

    }





    

}

