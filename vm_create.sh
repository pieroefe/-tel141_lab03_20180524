#!/bin/bash
# ==========================================================
# vm_create.sh – Crea una VM Cirros y la conecta al OVS
# ==========================================================

VM_NAME=$1        # Nombre de la VM
VNC_NUM=$2        # Número de pantalla VNC
TAP_NAME=$3       # Nombre de interfaz TAP
VLAN_ID=$4        # VLAN asociada
IMAGE="/home/ubuntu/cirros-0.5.1-x86_64-disk.img"

echo "[INFO] Creando $VM_NAME (VLAN $VLAN_ID, VNC $VNC_NUM)..."

# Crear interfaz TAP
sudo ip tuntap add dev $TAP_NAME mode tap user ubuntu || true
sudo ip link set $TAP_NAME up

# Agregar al bridge con su VLAN
sudo ovs-vsctl --may-exist add-port br-int $TAP_NAME tag=$VLAN_ID

# Generar MAC válida
MAC=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

# Lanzar la VM (modo snapshot, sin persistencia)
sudo qemu-system-x86_64 -enable-kvm -m 256 -smp 1 \
  -hda $IMAGE \
  -netdev tap,id=nd_${VM_NAME},ifname=${TAP_NAME},script=no,downscript=no \
  -device e1000,netdev=nd_${VM_NAME},mac=${MAC} \
  -vnc 0.0.0.0:${VNC_NUM} \
  -daemonize -snapshot \
  -D /var/log/qemu/${VM_NAME}.log \
  -pidfile /var/log/qemu/${VM_NAME}.pid \
  -name ${VM_NAME}

echo "✅ VM '$VM_NAME' lista:"
echo "   TAP=${TAP_NAME} (VLAN=${VLAN_ID}) en br-int"
echo "   MAC=${MAC}"
echo "   VNC=:${VNC_NUM} (TCP $((5900 + VNC_NUM)))"
echo "   Log: /var/log/qemu/${VM_NAME}.log"
