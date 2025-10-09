#!/usr/bin/env bash
set -euo pipefail
# Fase 2: Headnode + OFS

HEADNODE_IP="${HEADNODE_IP:-10.0.10.1}"
OFS_IP="${OFS_IP:-10.0.10.5}"

OVS_HN="${OVS_HN:-br-int}"
UPLINK_HN="${UPLINK_HN:-ens4}"          # uplink real del headnode
INET_IF="${INET_IF:-ens3}"
VLANS="${VLANS:-100,200,30}"

OVS_OFS="${OVS_OFS:-br-ofs}"
OFS_PORTS_CSV="${OFS_PORTS_CSV:-ens5,ens6,ens7,ens8}"  # incluye ens5 (hacia headnode)

echo "----------------------------------------------------"
echo "[INFO] Iniciando Fase 2: Headnode + OFS"
echo "----------------------------------------------------"

echo "[INFO] Configurando Headnode localmente..."
sudo /home/ubuntu/init_headnode.sh "${OVS_HN}" "${UPLINK_HN}" "${INET_IF}" "${VLANS}"

echo "[INFO] Configurando OFS remoto (${OFS_IP})..."
ssh -o StrictHostKeyChecking=no ubuntu@"${OFS_IP}" \
  "sudo /home/ubuntu/init_ofs.sh '${OVS_OFS}' '${OFS_PORTS_CSV}' '${VLANS}'"

echo "----------------------------------------------------"
echo "[OK] Fase 2 completada."

