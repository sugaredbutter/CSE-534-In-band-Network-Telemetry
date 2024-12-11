const bit<16> TYPE_IPV4 = 0x800;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_t{
    bit<16> srcPort;
	bit<16> dstPort;
	bit<16> length;
	bit<16> checksum;

}

header INT_shim_t {
    bit<4>    type;
    bit<2>    NPT;
    bit<2>    rsvd;
    bit<8>    length;
    bit<16>   etc;
}

header INT_header_t {
    bit<4>    Ver;    //Should be 2
    bit<1>    D;      //1 = Discard Packet
    bit<1>    E;      //1 = Max Hop Count exceeded
    bit<1>    M;      //1 = MTU exceeded
    bit<12>   R;      //0 Reserved bits
    bit<5>    hopML;  //Per-hop Metadata length
    bit<8>    remHopCount;   //remaining hop count

}

header INT_bitmap_t {
    bit<1>    nodeID;                   //(4 bytes)
    bit<1>    lvl1_ingress_egress_ID;   //16 bits each (4 bytes)
    bit<1>    hopLatency;               //(4 bytes)
    bit<1>    queueInfo;                //ID = 8 bits and Q occupance = 24 bits (4 bytes)
    bit<1>    ingressTS;                //8 bytes (8 bytes)
    bit<1>    egressTS;                 //8 bytes (8 bytes)
    bit<1>    lvl2_ingress_egress_ID;   //4 bytes each (8 bytes)
    bit<1>    egressTx;                 //(4 bytes)
    bit<1>    bufferInfo;               //buffer ID (8 bits) and buffer occupancy (24 bits) (4 bytes)
    bit<6>    rsvd;
    bit<1>    checksumComplement;       //(4 bytes)
}

header INT_payload_t {
    varbit<2000> data;
}

header nodeID_t {
    bit<32> nodeID;
}

header lvl1_ID_t {
    bit<16> ingressID;
    bit<16> egressID;
}

header hop_latency_t {
    bit<32> hop_latency;
}

header queueInfo_t {
    bit<8> queueID;
    bit<24> queueOccupancy;
}

header ingressTS_t {
    bit<64> ingressTS;
}

header egressTS_t {
    bit<64> egressTS;
}

header lvl2_ID_t {
    bit<32> ingressID;
    bit<32> egressID;

}

header egressTX_t {
    bit<32> egressTX;
}

header bufferInfo_t {
    bit<8> bufferID;
    bit<24> bufferOcc;
}
const bit<8> CLONE = 0;

struct metadata {
    @field_list(CLONE)
    ip4Addr_t dstAddr;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
    udp_t        dummy_udp;    //For INT
    INT_shim_t   INT_shim;
    INT_header_t INT_header;
    INT_bitmap_t INT_bitmap;
    INT_payload_t INT_payload;
    nodeID_t     nodeID;
    lvl1_ID_t    lvl1_ID;
    hop_latency_t hop_latency;
    queueInfo_t  queueInfo;
    ingressTS_t  ingressTS;
    egressTS_t  egressTS;
    lvl2_ID_t   lvl2_ID;
    egressTX_t egressTX;
    bufferInfo_t bufferInfo;
}

