#!/bin/bash
# Configura el switch intermedio (OFS)

BRIDGE="br-ofs"
PORTS=("ens4" "ens5" "ens6")

sudo ovs-vsctl --may-exist add-br $BRIDGE

for p in "${PORTS[@]}"; do
    sudo ovs-vsctl --may-exist add-port $BRIDGE $p
    sudo ovs-vsctl set port $p trunks=100,200,300
done

echo "[OK] OFS listo con $BRIDGE y puertos trunk"

