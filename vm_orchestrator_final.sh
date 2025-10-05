#!/usr/bin/env bash
set -euo pipefail
# ----------------------------------------------------
# vm_orchestrator_final.sh (versión final)
# Ejecuta Fase 1 + Fase 2 completas
# ----------------------------------------------------

cd /home/ubuntu

bash ./vm_orchestrator_fase1.sh
bash ./vm_orchestrator_fase2.sh

echo "----------------------------------------------------"
echo "? Topología completa (Fase1 + Fase2) desplegada sin errores."
echo "----------------------------------------------------"
