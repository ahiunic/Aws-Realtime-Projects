#!/bin/bash
exec > /var/log/userdata.log 2>&1
set -x

# Update system
yum update -y

# Install Docker + dependencies
yum install -y docker containerd git screen nc

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl enable docker --now
usermod -a -G docker ec2-user
if id "ssm-user" &>/dev/null; then
  usermod -a -G docker ssm-user
fi

# Wait for DB (max 5 min)
for i in {1..30}; do
  nc -z -w5 petclinic.c5my6wm2c2rx.ap-south-1.rds.amazonaws.com 3306 && break
  echo "⏳ Waiting for DB..."
  sleep 10
done

# Pull and run Petclinic container
docker run -d \
  --name petclinic_app \
  -e MYSQL_URL=jdbc:mysql://petclinic.c5my6wm2c2rx.ap-south-1.rds.amazonaws.com:3306/petclinic \
  -e MYSQL_USER=petclinic \
  -e MYSQL_PASSWORD=petclinic \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=petclinic \
  -p 80:8080 \
  docker.io/karthik0741/images:petclinic_img
