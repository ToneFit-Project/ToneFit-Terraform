#!/bin/bash
set -e

# Java 21 설치
dnf install -y java-21-amazon-corretto

# Nginx 설치
dnf install -y nginx
systemctl enable nginx

# Nginx 리버스 프록시 설정
cat > /etc/nginx/conf.d/tonefit.conf << 'NGINXEOF'
server {
    listen 80;

    location / {
        proxy_pass         http://localhost:8080;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
NGINXEOF

systemctl start nginx

# 앱 디렉토리 생성
mkdir -p /app
chown ec2-user:ec2-user /app

# systemd 서비스 등록
cat > /etc/systemd/system/tonefit.service << 'SERVICEEOF'
[Unit]
Description=ToneFit Spring Boot Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/app
ExecStart=/usr/bin/java -jar /app/app.jar
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tonefit

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable tonefit
