# CSE-534-In-band-Network-Telemetry
Hello, this is my very basic implementation of INT in FABRIC. 

It is not robust, but it does successfully send telemetry data to an INT collector, and you can gather useful telemetry data from it.
There are some limitations I have not had the time of investigating/implementing such as MTU considerations and optimization (runs considerably slower than
FABRIC's P4 lab implementation) when running on BMv2 software switches. Implementation probably differs greatly from other implementations since I wanted
to implement in my own way while trying to follow P4's documentation on INT. But overall, I was happy that it worked!

I am new to P4 which was sort of the motivation for why I chose topic. There is definitely room for improvement, but I certainly learned a lot
more about P4 through this. Anyway, apologies for any issues with the code.

The P4 program can act as a source, hop, and sink. It currently appends metadata and headers to all packets (except ipv6 currently).

It acts as a source when a parsed packet (that is not ipv6 currently) has no INT header.

It acts a hop when a parsed packet contains INT header and next hop is NOT the destination.

It finally acts as a sink when the next hop is the destination (exact match).
It then clones the packet and sends the cloned packet to the collector and strips the original packet of all telemetry data.

The INT collector address is currently defined in egress in this snippet.
```
if(hdr.ipv4.isValid() && standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_CLONE) {
    hdr.ipv4.dstAddr = 0xC0A80502;
    if(ipv4_exact.apply().miss) {
        ipv4_lpm.apply();
    }
}
```
THe INT collectors use Python to receive packets and store them in a csv file. I then use R to create graphs from the aquired telemetry data. Here is an example of switch 1
being the bottleneck, in which the queue is filled and the hop latency is large.
![image](https://github.com/user-attachments/assets/f2f2a6cf-7f5b-4726-b6ac-6c5eafd024a1)
![image](https://github.com/user-attachments/assets/45ae68e9-05b6-4f30-9be7-bff7c6f42f56)
