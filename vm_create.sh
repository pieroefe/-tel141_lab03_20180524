#!/bin/bash
# Crea una VM con QEMU y la conecta al bridge con VLAN

VM=$1         # nombre de la VM
VLAN=$2       # VLAN (100,200,300)
VNC=$3        # número de display VNC
MAC=$4        # dirección MAC

BRIDGE="br-int"
TAP="tap_${VM}_${VLAN}"
IMG="./cirros-0.5.1-x86_64-disk.img"

# Crear interfaz TAP
sudo ip tuntap add dev $TAP mode tap user $(whoami)
sudo ip link set $TAP up
sudo ovs-vsctl --may-exist add-port $BRIDGE $TAP tag=$VLAN

# Iniciar VM
qemu-system-x86_64 \
  -enable-kvm \
  -vnc 0.0.0.0:$VNC \
  -netdev tap,id=$TAP,ifname=$TAP,script=no,downscript=no \
  -device e1000,netdev=$TAP,mac=$MAC \
  -daemonize \
  -snapshot \
  $IMG

echo "[OK] VM $VM creada en VLAN $VLAN (VNC :$VNC)"

