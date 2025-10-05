#!/bin/bash
# ==========================================
# init_headnode.sh – Configura el Headnode
# Crea el bridge principal, habilita NAT y
# lanza los namespaces DHCP por VLAN
# ==========================================

OVS_BR="br-int"
UPLINK="ens4"

echo "[INFO] Creando bridge $OVS_BR..."
sudo ovs-vsctl --may-exist add-br $OVS_BR
sudo ip link set $OVS_BR up

echo "[INFO] Conectando interfaz uplink ($UPLINK) al bridge..."
sudo ovs-vsctl add-port $OVS_BR $UPLINK trunks=100,200,30

echo "[INFO] Habilitando reenvío IP y NAT..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

echo "[INFO] Creando namespaces DHCP por VLAN..."
sudo ./ns_create.sh ns-dhcp100 $OVS_BR 100 "192.168.100.10,192.168.100.100,255.255.255.0,12h" 192.168.100.1
sudo ./ns_create.sh ns-dhcp200 $OVS_BR 200 "192.168.200.10,192.168.200.100,255.255.255.0,12h" 192.168.200.1
sudo ./ns_create.sh ns-dhcp30  $OVS_BR 30  "192.168.30.10,192.168.30.100,255.255.255.0,12h"  192.168.30.1

echo "[OK] Headnode configurado con bridge $OVS_BR y namespaces DHCP activos."
