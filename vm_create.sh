#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 4 ]]; then echo "Uso: $0 <VM_NAME> <OVS_BR> <VLAN_ID> <VNC_PORT>"; exit 1; fi
VM=$1; BR=$2; VLAN=$3; VNC=$4
IMG="/root/cirros-0.5.1-x86_64-disk.img"

[ -f "$IMG" ] || wget -O "$IMG" -c https://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img

TAP="tap_${VM}_${VLAN}"
ip tuntap add mode tap name "$TAP"
ip link set "$TAP" up
ovs-vsctl --may-exist add-port "$BR" "$TAP" tag="$VLAN"

MAC="02:$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g;s/:$//')"
qemu-system-x86_64 -enable-kvm -vnc 0.0.0.0:$VNC \
  -netdev tap,id=nd0,ifname="$TAP",script=no,downscript=no \
  -device e1000,netdev=nd0,mac="$MAC" \
  -daemonize -snapshot "$IMG"

echo "[OK] VM $VM creada en VLAN $VLAN (VNC :$VNC)"
