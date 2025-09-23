#!/usr/bin/env bash
set -euo pipefail
OVS_BR_DEFAULT="br-int"
IFACES_DEFAULT=("ens4" "ens5" "ens6")
RESERVED_IFACES=("ens3")

if [[ $EUID -ne 0 ]]; then echo "Ejecuta como root"; exit 1; fi

OVS_BR="${1:-$OVS_BR_DEFAULT}"
shift || true
IFACES=("${@:-${IFACES_DEFAULT[@]}}")

for i in "${IFACES[@]}"; do
  [[ " ${RESERVED_IFACES[*]} " == *" $i "* ]] && { echo "Bloqueado: $i"; exit 1; }
done

if ! ovs-vsctl br-exists "$OVS_BR"; then
  ovs-vsctl add-br "$OVS_BR"
fi
ip link set dev "$OVS_BR" up

for i in "${IFACES[@]}"; do
  ip addr flush dev "$i" || true
  ip link set dev "$i" up
  ovs-vsctl --may-exist add-port "$OVS_BR" "$i"
done
echo "[OK] OFS listo en $OVS_BR con ${IFACES[*]}"
