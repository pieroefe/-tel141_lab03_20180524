#!/bin/bash
# Orquestador: crea VMs en los Workers

WORKERS=("10.0.10.2" "10.0.10.3" "10.0.10.4")

echo "[*] Inicializando Workers..."
for node in "${WORKERS[@]}"; do
    ssh ubuntu@$node "~/init_worker.sh br-int ens4"
done

echo "[*] Creando VMs..."
# Cada Worker tendrá 3 VMs en VLANs 100,200,300
# VNCs únicos por Worker: server2(:1-3), server3(:4-6), server4(:7-9)

for i in "${!WORKERS[@]}"; do
    NODE=${WORKERS[$i]}
    OFFSET=$((i*3))
    VLANs=(100 200 300)
    for j in {0..2}; do
        VM="vm$((j+1))"
        VNC=$((OFFSET+j+1))
        MAC="52:54:00:00:${VLANs[$j]}:$VNC"
        ssh ubuntu@$NODE "~/vm_create.sh $VM ${VLANs[$j]} $VNC $MAC"
    done
done

echo "[OK] VMs desplegadas en Workers"
