#!/bin/bash
# Inicializa el bridge en cada Worker

BRIDGE=${1:-br-int}
UPLINK=${2:-ens4}

# Crear bridge
sudo ovs-vsctl --may-exist add-br $BRIDGE

# Conectar la interfaz física como trunk con VLANs 100,200,300
sudo ovs-vsctl --may-exist add-port $BRIDGE $UPLINK
sudo ovs-vsctl set port $UPLINK trunks=100,200,300

echo "[OK] $BRIDGE listo en $(hostname)"

