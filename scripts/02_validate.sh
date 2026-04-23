#!/bin/bash
ALB_URL=$(cd ../terraform && terraform output -raw frontend_url)

echo "Validando Endpoints de TechNova en: $ALB_URL"
echo "------------------------------------------------"

check_url() {
    echo -n "Probando $1... "
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$1")
    if [ "$STATUS" == "200" ]; then
        echo "✅ [200 OK]"
    else
        echo "❌ [$STATUS]"
    fi
}

check_url "$ALB_URL"
check_url "$ALB_URL/api/productos"
check_url "$ALB_URL/api/pedidos"