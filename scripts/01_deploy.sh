#!/bin/bash
echo "Verificando credenciales de AWS..."
aws sts get-caller-identity > /dev/null || { echo "ERROR: Exporta tus credenciales de Learner Lab"; exit 1; }

cd ../terraform
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"