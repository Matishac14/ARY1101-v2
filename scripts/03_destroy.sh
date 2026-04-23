#!/bin/bash
read -p "ADVERTENCIA: ¿Estás seguro de destruir TODA la infraestructura? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ../terraform
    terraform destroy -auto-approve
fi