#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   sudo ./init_worker.sh <nombre-ovs> <if1> [if2 ...]
# Ejemplo:
#   sudo ./init_worker.sh br-int ens4

OVS_BR="${1:-br-int}"
shift || true
IFACES=("$@")

die(){ echo "[ERROR] $*" >&2; exit 1; }
[[ ${#IFACES[@]} -eq 0 ]] && die "Debes indicar al menos 1 interfaz física."

for i in "${IFACES[@]}"; do
  [[ "$i" == "ens3" ]] && die "ens3 está prohibida por consigna."
  ip link show "$i" >/dev/null 2>&1 || die "Interfaz $i no existe."
done

# Si existe un Linux bridge homónimo, eliminarlo (best-effort)
if ip link show "$OVS_BR" >/dev/null 2>&1; then
  if command -v brctl >/dev/null 2>&1 && brctl show 2>/dev/null | grep -q "^$OVS_BR"; then
    echo "[*] Eliminando Linux bridge conflictivo $OVS_BR"
    ip link set dev "$OVS_BR" down || true
    ip link del "$OVS_BR" || true
  fi
fi

# Asegurar servicio de OVS (si aplica)
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now openvswitch-switch >/dev/null 2>&1 || true
fi

# Crear/asegurar OvS
ovs-vsctl --may-exist add-br "$OVS_BR"
ip link set dev "$OVS_BR" up

# Conectar interfaces como TRUNK
for i in "${IFACES[@]}"; do
  echo "[*] Añadiendo $i a $OVS_BR (trunk)"
  ip addr flush dev "$i" || true
  ip link set dev "$i" up
  # Eliminar el puerto desde cualquier bridge si ya existiera (no abortar)
  ovs-vsctl --if-exists del-port "$i" 2>/dev/null || true
  ovs-vsctl add-port "$OVS_BR" "$i" -- set port "$i" vlan_mode=trunk
done

echo "[✓] Worker listo: $OVS_BR con puertos: ${IFACES[*]}"
