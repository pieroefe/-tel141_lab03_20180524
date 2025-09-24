#!/usr/bin/env bash
set -euo pipefail

# ====== INVENTARIO ======
USER="ubuntu"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

HEADNODE="${USER}@10.0.10.1"   # No se usa en Fase 1
WORKERS=(
  "${USER}@10.0.10.2"          # server2 = worker1
  "${USER}@10.0.10.3"          # server3 = worker2
  "${USER}@10.0.10.4"          # server4 = worker3
)
OFS_HOST="${USER}@10.0.10.5"   # ofs

# ====== PARÁMETROS DE RED (NO usar ens3) ======
OFS_OVS="br-core"
WORKER_OVS="br-int"

OFS_IFACES=("ens4" "ens5" "ens7")
W1_IFACES=("ens4")
W2_IFACES=("ens4")
W3_IFACES=("ens4")

# ====== IMAGEN DE LA VM (sin sudo) ======
VM_IMAGE="/home/ubuntu/images/cirros-0.5.1-x86_64-disk.img"
CIRROS_URL="https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img"

PREP_CMD=$(cat <<'PREP'
set -e
mkdir -p /home/ubuntu/images
cd /home/ubuntu/images
if [ ! -f cirros-0.5.1-x86_64-disk.img ]; then
  echo "[*] Descargando imagen base (una sola vez)..."
  wget -q "https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img" -O cirros-0.5.1-x86_64-disk.img
fi
PREP
)

# ====== DEFINICIÓN DE VMs ======
declare -a VMS_W1=( "vm1a 100 1 $VM_IMAGE" "vm1b 200 2 $VM_IMAGE" )
declare -a VMS_W2=( "vm2a 100 3 $VM_IMAGE" )
declare -a VMS_W3=( "vm3a 200 4 $VM_IMAGE" "vm3b 300 5 $VM_IMAGE" )

# Rutas remotas de scripts (deben existir en $HOME del usuario y tener +x)
R_INIT_WORKER="~/init_worker.sh"
R_VM_CREATE="~/vm_create.sh"
R_INIT_OFS="~/init_ofs.sh"

die(){ echo "[ERROR] $*" >&2; exit 1; }

# 0) Verificación SSH
for h in "$OFS_HOST" "${WORKERS[@]}"; do
  echo "[*] Verificando SSH en $h"
  ssh $SSH_OPTS "$h" "echo ok" >/dev/null || die "No puedo conectar a $h"
done

# 1) Inicializar OFS
echo "[*] Inicializando OFS: $OFS_HOST :: $OFS_OVS ${OFS_IFACES[*]}"
ssh $SSH_OPTS "$OFS_HOST" "sudo $R_INIT_OFS $OFS_OVS ${OFS_IFACES[*]}"

# 2) Inicializar Workers
for idx in "${!WORKERS[@]}"; do
  HOST="${WORKERS[$idx]}"
  declare VAR="W$((idx+1))_IFACES[@]"
  IFACES=("${!VAR}")
  echo "[*] Inicializando Worker$((idx+1)) en $HOST :: $WORKER_OVS ${IFACES[*]}"
  ssh $SSH_OPTS "$HOST" "sudo $R_INIT_WORKER $WORKER_OVS ${IFACES[*]}"
done

# 3) Preparar imagen en cada worker (sin sudo)
echo "[*] Preparando imagen en workers: $(basename "$VM_IMAGE")"
for HOST in "${WORKERS[@]}"; do
  echo "    - $HOST"
  ssh $SSH_OPTS "$HOST" "bash -lc '$PREP_CMD'"
done

# 4) Crear VMs por worker
create_vms() {
  local host="$1"; shift
  local -n arr="$1"; shift
  for def in "${arr[@]}"; do
    read -r VM_NAME VLAN VNC IMG <<<"$def"
    echo "[*] Creando VM $VM_NAME en $host (VLAN $VLAN, VNC :$VNC)"
    ssh $SSH_OPTS "$host" "sudo $R_VM_CREATE $VM_NAME $WORKER_OVS $VLAN $VNC $IMG"
  done
}
create_vms "${WORKERS[0]}" VMS_W1
create_vms "${WORKERS[1]}" VMS_W2
create_vms "${WORKERS[2]}" VMS_W3

echo "[✓] Fase 1 desplegada: OFS + Workers + VMs/VLAN. Headnode queda para Fase 2."

