import socket
import csv
from datetime import datetime
from scapy.all import *

ETH_HEADER_LENGTH = 14
IP4_HEADER_LENGTH = 20
DUMMY_UDP_HEADER_LENGTH = 8
INT_SHIM_LENGTH = 4
INT_HEADER_LENGTH = 4
INT_BITMAP_LENGTH = 2
INT_CONTENT_LENGTH = 0 #Variable
output_file = "telemetry_data.csv"

def receive_and_parse_packets(interface):
    s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))
    s.bind((interface, 0))

    print(f"Listening for packets on {interface}...")
    try:
        csvCount = 1
        while True:
            packet, addr = s.recvfrom(65535)
            print(f"Packet length: {len(packet)}")
            count = 0

            #Parse packet, dividing it into the relevant headers
            eth_header = packet[:ETH_HEADER_LENGTH]
            count += ETH_HEADER_LENGTH
            ip4_header = packet[count:count + IP4_HEADER_LENGTH]
            count += IP4_HEADER_LENGTH
            dummy_header = packet[count:count + DUMMY_UDP_HEADER_LENGTH]
            count += DUMMY_UDP_HEADER_LENGTH
            shim_header = packet[count:count + INT_SHIM_LENGTH]
            count += INT_SHIM_LENGTH
            int_header = packet[count:count + INT_HEADER_LENGTH]
            count += INT_HEADER_LENGTH
            bitmap_header = packet[count:count + INT_BITMAP_LENGTH]
            count += INT_BITMAP_LENGTH
            print(dummy_header)
            (eth_dst, eth_src, eth_etherType) = struct.unpack('!6s6sH', eth_header)
            (ip4_ver_ihl, ip4_diffserv, ip4_total_len, ip4_identification,
                 ip4_flags_frag_offset, ip4_ttl, ip4_protocol, ip4_hdr_checksum,
                 ip4_src, ip4_dst) = struct.unpack('!BBHHHBBH4s4s', ip4_header)
            (udp_srcPort, udp_dstPort, udp_length, udp_checksum) = struct.unpack('!4H', dummy_header)
            combined, int_length, etc = struct.unpack("!BBH", shim_header)


            #Fields of Header
            int_type = (combined >> 4) & 0xF 
            int_npt = (combined >> 2) & 0x3 
            int_rsvd = combined & 0x3   

            raw_value = struct.unpack("!I", int_header)[0]

            int_ver = (raw_value >> 28) & 0xF
            int_d = (raw_value >> 27) & 0x1
            int_e = (raw_value >> 26) & 0x1
            int_m = (raw_value >> 25) & 0x1
            int_r = (raw_value >> 13) & 0xFFF       
            int_hopML = (raw_value >> 8) & 0x1F     
            int_remHopCount = raw_value & 0xFF      

            
            bitmap = struct.unpack("!H", bitmap_header)[0]

            bitmap_nodeID = (bitmap >> 15) & 0x1
            bitmap_lvl1_ingress_egress_ID = (bitmap >> 14) & 0x1
            bitmap_hopLatency = (bitmap >> 13) & 0x1
            bitmap_queueInfo = (bitmap >> 12) & 0x1
            bitmap_ingressTS = (bitmap >> 11) & 0x1
            bitmap_egressTS = (bitmap >> 10) & 0x1
            bitmap_lvl2_ingress_egress_ID = (bitmap >> 9) & 0x1
            bitmap_egressTx = (bitmap >> 8) & 0x1
            bitmap_bufferInfo = (bitmap >> 7) & 0x1
            bitmap_rsvd = (bitmap >> 17) & 0x3F  # Reserved: 6 bits
            bitmap_checksumComplement = (bitmap >> 0) & 0x1

            print(socket.inet_ntoa(ip4_src))
            print(int_length, int(int_length))
            print(int_hopML)
            print(bitmap_header, bitmap_nodeID, bitmap_lvl1_ingress_egress_ID, bitmap_hopLatency, bitmap_queueInfo, bitmap_ingressTS, bitmap_egressTS, bitmap_lvl2_ingress_egress_ID, bitmap_egressTx, bitmap_bufferInfo, bitmap_rsvd, bitmap_checksumComplement)

            #Gather telemetry and add it to csv
            nodeID = []
            lvl1_ie = []
            hopLatency = []
            queueInfo = []
            ingressTS = []
            egressTS = []
            lvl2_ie = []
            egressTX = []
            bufferInfo = []
            checksumComp = []
            telemetryData = packet[count:count + int_length * int_hopML * 4]
            print(telemetryData)
            headers = [
                "Count", "Timestamp", "NodeID", "Lvl1_Ingress_ID", "Lvl1_Egress_ID", "HopLatency", "QueueID", "QueueDepth", "IngressTS", "EgressTS", "Lvl2_IE", "EgressTX", "BufferInfo", "ChecksumComp"
            ]
            try:
                with open(output_file, mode='x', newline='') as file:
                    writer = csv.writer(file)
                    writer.writerow(headers)
            except FileExistsError:
                print(f"{output_file} already exists. Appending data.")
            time = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            
            for x in range(0, int_length):
                currentTelemetry = telemetryData[:int_hopML * 4]
                telemetryData = telemetryData[int_hopML * 4:]
                row = {
                    "Count": csvCount,
                    "Timestamp": time,
                    "NodeID": None,
                    "Lvl1_Ingress_ID": None,
                    "Lvl1_Egress_ID": None,
                    "HopLatency": None,
                    "QueueID": None,
                    "QueueDepth": None,
                    "IngressTS": None,
                    "EgressTS": None,
                    "Lvl2_IE": None,
                    "EgressTX": None,
                    "BufferInfo": None,
                    "ChecksumComp": None
                }
                if bitmap_nodeID == 1:
                    row["NodeID"] = int.from_bytes(currentTelemetry[:4], byteorder='big')
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_lvl1_ingress_egress_ID == 1:
                    row["Lvl1_Ingress_ID"] = int.from_bytes(currentTelemetry[:2], byteorder='big')
                    row["Lvl1_Egress_ID"] = int.from_bytes(currentTelemetry[2:4], byteorder='big')
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_hopLatency == 1:
                    row["HopLatency"] = int.from_bytes(currentTelemetry[:4], byteorder='big')
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_queueInfo == 1:
                    row["QueueID"] = int.from_bytes(bytes(currentTelemetry[0]), byteorder='big')
                    row["QueueDepth"] = int.from_bytes(currentTelemetry[1:4], byteorder='big')
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_ingressTS == 1:
                    row["IngressTS"] = int.from_bytes(currentTelemetry[:8], byteorder='big')
                    currentTelemetry = currentTelemetry[8:]
                if bitmap_egressTS == 1:
                    row["EgressTS"] = int.from_bytes(currentTelemetry[:8], byteorder='big')
                    currentTelemetry = currentTelemetry[8:]
                if bitmap_lvl2_ingress_egress_ID == 1:
                    row["Lvl2_IE"] = currentTelemetry[:8]
                    currentTelemetry = currentTelemetry[8:]
                if bitmap_egressTx == 1:
                    row["EgressTX"] = currentTelemetry[:4]
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_bufferInfo == 1:
                    row["BufferInfo"] = currentTelemetry[:4]
                    currentTelemetry = currentTelemetry[4:]
                if bitmap_checksumComplement == 1:
                    row["ChecksumComp"] = currentTelemetry[:4]
                    currentTelemetry = currentTelemetry[4:]
                with open(output_file, mode='a', newline='') as file:
                    writer = csv.DictWriter(file, fieldnames=headers)
                    writer.writerow(row)
            csvCount += 1
    except KeyboardInterrupt:
        print("\nStopping packet capture.")
    finally:
        s.close()

if __name__ == "__main__":
    network_interface = "enp7s0"  
    receive_and_parse_packets(network_interface)
