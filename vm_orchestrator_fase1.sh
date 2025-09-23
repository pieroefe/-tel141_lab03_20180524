#!/usr/bin/env bash
set -euo pipefail
SSH_OPTS="-o StrictHostKeyChecking=no"
RESERVED=("ens3")

OFS_HOST="ubuntu@ofs-host"
WORKERS=("ubuntu@worker1" "ubuntu@worker2" "ubuntu@worker3")
OVS_BR="br-int"

OFS_PORTS=("ens4" "ens5" "ens6")
W1_PORTS=("ens4")
W2_PORTS=("ens4")
W3_PORTS=("ens4")

VM_DEF=(
  "vmA|0|100|1"
  "vmB|1|100|2"
  "vmC|2|200|3"
)

IMG_PATH="/root/cirros-0.5.1-x86_64-disk.img"
REMOTE_DIR="~/tel141_lab3"

run() { ssh $SSH_OPTS "$@"; }
copy() { scp $SSH_OPTS "$@"; }

echo "[*] Inicializando Workers..."
run "${WORKERS[0]}" "cd $REMOTE_DIR && sudo ./init_worker.sh $OVS_BR ${W1_PORTS[*]}"
run "${WORKERS[1]}" "cd $REMOTE_DIR && sudo ./init_worker.sh $OVS_BR ${W2_PORTS[*]}"
run "${WORKERS[2]}" "cd $REMOTE_DIR && sudo ./init_worker.sh $OVS_BR ${W3_PORTS[*]}"

echo "[*] Inicializando OFS..."
run "$OFS_HOST" "cd $REMOTE_DIR && sudo ./init_ofs.sh $OVS_BR ${OFS_PORTS[*]}"

echo "[*] Creando VMs..."
for entry in "${VM_DEF[@]}"; do
  IFS='|' read -r VM IDX VLAN VNC <<<"$entry"
  WKR="${WORKERS[$IDX]}"
  run "$WKR" "cd $REMOTE_DIR && sudo ./vm_create.sh '$VM' '$OVS_BR' '$VLAN' '$VNC'"
done

echo "[✓] Fase 1 lista."
