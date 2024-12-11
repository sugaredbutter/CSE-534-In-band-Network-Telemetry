#echo "table_add MyIngress.ipv4_exact MyIngress.forward 192.168.2.20 => 00:00:00:00:00:04 1" | simple_switch_CLI
echo "table_add MyIngress.ipv4_lpm MyIngress.forward 192.168.1.0/24 => 00:00:00:00:00:03 0" | simple_switch_CLI
echo "table_add MyIngress.ipv4_lpm MyIngress.forward 192.168.4.0/24 => 00:00:00:00:00:06 1" | simple_switch_CLI
echo "mirroring_add 1 2" | simple_switch_CLI