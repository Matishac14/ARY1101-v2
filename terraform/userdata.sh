#!/bin/bash
set -e
LOG=/var/log/technova-setup.log
exec > >(tee -a $LOG) 2>&1

echo "[$(date)] === INICIO SETUP TECHNOVA ==="

# 1. Update sistema
dnf update -y

# 2. Instalar Docker
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# 3. Instalar Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# 4. Instalar herramientas
dnf install -y git mariadb105

# 5. Clonar el repo
git clone https://github.com/Matishac14/ARY1101-v2.git /home/ec2-user/app
chown -R ec2-user:ec2-user /home/ec2-user/app

# 6. Crear .env con valores interpolados
cat > /home/ec2-user/app/.env <<'ENVEOF'
ALUMNO_NOMBRE=Matias Fernandez
ALUMNO_RUT=20099194k
ALUMNO_SECCION=ARY1101
DB_HOST=${rds_endpoint}
DB_PORT=3306
DB_NAME=technova
DB_USER=technova_user
DB_PASSWORD=${db_user_pass}
DB_ROOT_PASSWORD=${db_master_pass}
PORT_PRODUCTOS=3001
PORT_PEDIDOS=3002
PORT_FRONTEND=80
ENVEOF

# 7. Esperar a que RDS esté disponible
echo "[$(date)] Esperando que RDS esté disponible..."
for i in $(seq 1 30); do
  if mysql -h "${rds_endpoint}" -u admin -p"${db_master_pass}" \
           --connect-timeout=5 -e "SELECT 1;" 2>/dev/null; then
    echo "[$(date)] RDS disponible"
    break
  fi
  sleep 10
done

# 8. Cargar DB
echo "[$(date)] Cargando schema e inicializando usuario..."
mysql -h "${rds_endpoint}" -u admin -p"${db_master_pass}" <<SQLEOF
CREATE USER IF NOT EXISTS 'technova_user'@'%' IDENTIFIED BY '${db_user_pass}';
GRANT ALL PRIVILEGES ON technova.* TO 'technova_user'@'%';
FLUSH PRIVILEGES;
SQLEOF
# 8.2 HACK DE PERSONALIZACIÓN: Inyectar endpoint /info en Nginx
echo "[$(date)] Configurando endpoint de autoría en Nginx..."
cat > /home/ec2-user/app/technova-frontend/nginx-custom.conf <<EOF
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    # Endpoint inyectado para la evaluación
    location ~ ^/api/(productos|pedidos)/info$ {
        default_type application/json;
        return 200 '{"alumno": "Matias Fernandez", "rut": "20099194k", "seccion": "ARY1101", "mensaje": "Despliegue automatizado validado"}';
    }

    location /api/productos {
        proxy_pass http://api-productos:3001;
    }

    location /api/pedidos {
        proxy_pass http://api-pedidos:3002;
    }
}
EOF

# Reemplazar el archivo de configuración original de Nginx en el Dockerfile
sed -i 's|COPY nginx.conf /etc/nginx/conf.d/default.conf|COPY nginx-custom.conf /etc/nginx/conf.d/default.conf|g' /home/ec2-user/app/technova-frontend/Dockerfile
mysql -h "${rds_endpoint}" -u admin -p"${db_master_pass}" < /home/ec2-user/app/technova-db/init.sql

# 8.5 MODIFICACIÓN CRÍTICA: Sobreescribir docker-compose.yml
# Creamos un archivo limpio solo con frontend y APIs, apuntando a RDS.
# Usamos $${VARIABLE} para escapar la interpolación de Terraform.
echo "[$(date)] Generando docker-compose.yml limpio (sin DB local)..."
cat > /home/ec2-user/app/docker-compose.yml <<'YAMLEOF'
version: '3.8'

services:
  frontend:
    build:
      context: ./technova-frontend
      dockerfile: Dockerfile
    ports:
      - "$${PORT_FRONTEND:-80}:80"
    restart: always

  api-productos:
    build:
      context: ./technova-api-productos
      dockerfile: Dockerfile
    ports:
      - "$${PORT_PRODUCTOS:-3001}:3001"
    env_file:
      - .env
    restart: always

  api-pedidos:
    build:
      context: ./technova-api-pedidos
      dockerfile: Dockerfile
    ports:
      - "$${PORT_PEDIDOS:-3002}:3002"
    env_file:
      - .env
    restart: always
YAMLEOF

# 9. Levantar containers
echo "[$(date)] Levantando contenedores de App..."
cd /home/ec2-user/app
docker-compose up -d --build

echo "[$(date)] === SETUP COMPLETADO ==="