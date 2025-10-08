#!/usr/bin/env bash
set -euo pipefail
# ----------------------------------------------------
# vm_orchestrator_fase2.sh (final)
# Ejecuta configuración Headnode + OFS
# ----------------------------------------------------

HEADNODE_IP="10.0.10.1"
OFS_IP="10.0.10.5"

OVS_HN="br-int"
UPLINK_HN="ens4"
INET_IF="ens3"
VLANS="100,200,30"

OVS_OFS="br-ofs"
OFS_PORTS="ens4,ens5,ens6"

echo "----------------------------------------------------"
echo "[INFO] Iniciando Fase 2: Configuración Headnode + OFS"
echo "----------------------------------------------------"

echo "[INFO] Configurando Headnode localmente..."
sudo /home/ubuntu/init_headnode.sh "${OVS_HN}" "${UPLINK_HN}" "${INET_IF}" "${VLANS}"

echo "[INFO] Configurando OFS remoto (${OFS_IP})..."
ssh -o StrictHostKeyChecking=no ubuntu@"${OFS_IP}" \
  "sudo /home/ubuntu/init_ofs.sh ${OVS_OFS} ${OFS_PORTS} ${VLANS}"

echo "----------------------------------------------------"
echo "Fase 2 completada exitosamente"
echo "----------------------------------------------------"
