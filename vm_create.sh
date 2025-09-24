#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   sudo ./vm_create.sh <VM_NAME> <OVS_BR> <VLAN_ID> <VNC_PORT> [<DISK_IMG>]
# Ejemplo:
#   sudo ./vm_create.sh vmA br-int 200 1 /home/ubuntu/images/cirros-0.5.1-x86_64-disk.img

VM_NAME="${1:?Falta VM_NAME}"
OVS_BR="${2:?Falta OVS_BR}"
VLAN_ID="${3:?Falta VLAN_ID}"
REQ_VNC="${4:?Falta VNC_PORT}"   # Esto es el "display": 1 → TCP 5901
DISK_IMG="${5:-/home/ubuntu/images/cirros-0.5.1-x86_64-disk.img}"

CIRROS_URL_DEFAULT="https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img"

TAP_IF="${VM_NAME}_tap"
MAC_HEX=$(printf "%06X" $((RANDOM%16777215)))
MAC="52:54:00:${MAC_HEX:0:2}:${MAC_HEX:2:2}:${MAC_HEX:4:2}"

die(){ echo "[ERROR] $*" >&2; exit 1; }

# --- Comprobaciones previas ---
command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 no está instalado."
command -v ovs-vsctl >/dev/null 2>&1 || die "openvswitch-switch/ovs-vsctl no instalado."
ovs-vsctl br-exists "$OVS_BR" || die "Bridge OvS $OVS_BR no existe."

# --- Imagen: auto-abastecimiento si falta (sin sudo) ---
if [[ ! -f "$DISK_IMG" ]]; then
  echo "[*] $DISK_IMG no existe; intentando descargar imagen base..."
  mkdir -p "$(dirname "$DISK_IMG")"
  if ! wget -q "${CIRROS_URL_DEFAULT}" -O "$DISK_IMG"; then
    die "No pude descargar la imagen automáticamente desde ${CIRROS_URL_DEFAULT}"
  fi
  echo "[✓] Imagen descargada en $DISK_IMG"
fi

# --- TAP idempotente ---
if ip link show "$TAP_IF" >/dev/null 2>&1; then
  echo "[*] Reusando TAP $TAP_IF"
else
  ip tuntap add dev "$TAP_IF" mode tap
fi
ip link set "$TAP_IF" up

# --- Conectar TAP al OvS con VLAN (limpieza robusta previa) ---
ovs-vsctl --if-exists del-port "$TAP_IF" 2>/dev/null || true
ovs-vsctl add-port "$OVS_BR" "$TAP_IF" tag="$VLAN_ID"

# --- Selección automática de display VNC libre ---
is_vnc_in_use() {
  local display="$1"
  local port=$((5900 + display))
  # ss es preferible; si no está, usa netstat si existe
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | awk '{print $4}' | grep -q ":${port}\$"
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${port}\$"
  else
    # Si no hay forma de detectar, asumimos libre
    return 1
  fi
}

ACT_VNC="$REQ_VNC"
MAX_TRIES=50
TRY=0
while is_vnc_in_use "$ACT_VNC"; do
  TRY=$((TRY+1))
  [[ $TRY -ge $MAX_TRIES ]] && die "No encontré display VNC libre a partir de :$REQ_VNC (probé $MAX_TRIES)."
  ACT_VNC=$((REQ_VNC + TRY))
done
if [[ "$ACT_VNC" != "$REQ_VNC" ]]; then
  echo "[*] VNC :$REQ_VNC ocupado; usaré :$ACT_VNC"
fi

# --- Aceleración KVM si disponible ---
KVM_OPTS=""
if [[ -e /dev/kvm ]]; then
  KVM_OPTS="-enable-kvm"
fi

# --- Lanzar la VM ---
echo "[*] Iniciando VM $VM_NAME (VNC :$ACT_VNC, MAC $MAC)"
qemu-system-x86_64 \
  ${KVM_OPTS} \
  -vnc 0.0.0.0:"$ACT_VNC" \
  -netdev tap,id="${TAP_IF}",ifname="${TAP_IF}",script=no,downscript=no \
  -device e1000,netdev="${TAP_IF}",mac="$MAC" \
  -daemonize \
  -snapshot \
  "$DISK_IMG"

echo "[✓] VM $VM_NAME creada y conectada a $OVS_BR con VLAN $VLAN_ID (VNC :$ACT_VNC)"
