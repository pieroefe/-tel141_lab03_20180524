#!/bin/bash
set -e
BRIDGE="br-int"
UPLINK="ens4"
VLANS="100,200,30"

echo "[INFO] Creando bridge $BRIDGE..."
sudo ovs-vsctl --may-exist add-br $BRIDGE
sudo ip link set $BRIDGE up

echo "[INFO] Configurando $UPLINK como trunk ($VLANS)..."
sudo ovs-vsctl --may-exist add-port $BRIDGE $UPLINK
sudo ovs-vsctl set Interface $UPLINK type=system
sudo ovs-vsctl set Port $UPLINK trunks=$VLANS
sudo ip link set $UPLINK up

echo "[OK] Worker configurado con $BRIDGE y VLANs activas."
