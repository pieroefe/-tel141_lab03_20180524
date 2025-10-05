#!/bin/bash
# ============================================================
# ns_create.sh <namespace> <ovs_bridge> <vlan_id> <dhcp_range> <gateway>
# Crea un Linux Network Namespace que actúa como servidor DHCP
# conectado al bridge OVS correspondiente a su VLAN
# ============================================================

NS=$1
OVS=$2
VLAN=$3
RANGE=$4
GW=$5

echo "[INFO] Creando namespace $NS..."
sudo ip netns add $NS

echo "[INFO] Creando interfaces virtuales..."
sudo ip link add ${NS}-tap type veth peer name ${NS}-br

echo "[INFO] Conectando ${NS}-br a $OVS con VLAN $VLAN..."
sudo ip link set ${NS}-br up
sudo ovs-vsctl add-port $OVS ${NS}-br tag=$VLAN

echo "[INFO] Configurando interfaz interna..."
sudo ip link set ${NS}-tap netns $NS
sudo ip netns exec $NS ip link set lo up
sudo ip netns exec $NS ip link set ${NS}-tap up
sudo ip netns exec $NS ip addr add ${GW}/24 dev ${NS}-tap

echo "[INFO] Iniciando servicio DHCP (dnsmasq) dentro de $NS..."
sudo ip netns exec $NS dnsmasq \
  --interface=${NS}-tap \
  --bind-interfaces \
  --port=0 \
  --dhcp-range=$RANGE \
  --dhcp-option=3,$GW \
  --log-facility=/var/log/${NS}_dnsmasq.log

echo "[OK] Namespace $NS listo. DHCP sirviendo en VLAN $VLAN."
