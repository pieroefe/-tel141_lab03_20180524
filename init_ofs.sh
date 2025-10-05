#!/usr/bin/env bash
# ==========================================================
# init_ofs.sh – Inicialización del OpenFlow Switch (OFS)
# ==========================================================
# Este script configura el switch intermedio (br-ofs)
# que conecta los Workers y el Headnode mediante VLAN trunking.
#
# VLANs activas: 30, 100, 200
# Interfaces físicas:
#   ens4 -> conexión al Headnode
#   ens7 -> conexión al Worker2
#   ens8 -> conexión al Worker3
# ==========================================================

set -euo pipefail

BR="br-ofs"
VLANS="30,100,200"
PORTS=("ens4" "ens7" "ens8")

echo "----------------------------------------------------"
echo "[INFO] Inicializando Open vSwitch en el OFS..."
echo "----------------------------------------------------"

# Asegurar que OVS esté activo
sudo systemctl start openvswitch-switch
sudo systemctl enable openvswitch-switch

# Eliminar bridge anterior si existe
if sudo ovs-vsctl br-exists "$BR"; then
  echo "[INFO] Eliminando bridge previo $BR..."
  sudo ovs-vsctl del-br "$BR"
  sleep 1
fi

# Crear nuevo bridge
echo "[INFO] Creando bridge $BR..."
sudo ovs-vsctl add-br "$BR"
sudo ovs-vsctl set bridge "$BR" other-config:hwaddr="fa:16:3e:$(hexdump -n3 -e '/1 "%02X"' /dev/urandom | tr 'A-F' 'a-f')"
sudo ip link set "$BR" up

# Configurar interfaces físicas
for IFACE in "${PORTS[@]}"; do
  echo "[INFO] Configurando interfaz $IFACE como trunk ($VLANS)..."
  sudo ip link set "$IFACE" up
  sudo ovs-vsctl --may-exist add-port "$BR" "$IFACE"
  sudo ovs-vsctl set Interface "$IFACE" type=system
  sudo ovs-vsctl set Port "$IFACE" trunks=$VLANS
done

# Mostrar configuración resultante
echo "----------------------------------------------------"
sudo ovs-vsctl show
echo "----------------------------------------------------"
echo "[OK] OFS configurado correctamente:"
echo "     - Bridge: $BR"
echo "     - VLANs trunk: $VLANS"
echo "     - Interfaces: ${PORTS[*]}"
echo "----------------------------------------------------"
