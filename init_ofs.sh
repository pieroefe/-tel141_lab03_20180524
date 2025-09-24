#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   sudo ./init_ofs.sh <nombre-ovs> <if1> [if2 ...]
# Ejemplo:
#   sudo ./init_ofs.sh br-core ens4 ens5 ens7

OVS_BR="${1:-br-core}"
shift || true
IFACES=("$@")

die(){ echo "[ERROR] $*" >&2; exit 1; }

[[ ${#IFACES[@]} -eq 0 ]] && die "Debes indicar interfaces de la Data Network."
for i in "${IFACES[@]}"; do
  [[ "$i" == "ens3" ]] && die "ens3 está prohibida por consigna."
  ip link show "$i" >/dev/null 2>&1 || die "Interfaz $i no existe."
done

# Asegurar servicio OVS (si aplica)
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now openvswitch-switch >/dev/null 2>&1 || true
fi

# Crear/asegurar OvS
ovs-vsctl --may-exist add-br "$OVS_BR"
ip link set dev "$OVS_BR" up

# Limpiar IPs y agregar puertos como TRUNK
for i in "${IFACES[@]}"; do
  echo "[*] Limpiando IP y agregando $i -> $OVS_BR (trunk)"
  ip addr flush dev "$i" || true
  ip link set dev "$i" up
  ovs-vsctl --if-exists del-port "$i" 2>/dev/null || true
  ovs-vsctl add-port "$OVS_BR" "$i" -- set port "$i" vlan_mode=trunk
done

echo "[✓] OFS listo: $OVS_BR con puertos troncales: ${IFACES[*]}"
