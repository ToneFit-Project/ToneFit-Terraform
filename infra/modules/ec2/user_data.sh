#!/bin/bash
set -e

# ── 패키지 설치 ────────────────────────────────────────────────
dnf install -y java-21-amazon-corretto nginx amazon-cloudwatch-agent

# ── Nginx — upstream 포트 스위칭 방식 ─────────────────────────
cat > /etc/nginx/conf.d/tonefit.conf << 'NGINXEOF'
upstream app {
    server 127.0.0.1:8080;
}

server {
    listen 80;

    location / {
        proxy_pass         http://app;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
NGINXEOF

systemctl enable nginx
systemctl start nginx

# ── 앱 디렉토리 ────────────────────────────────────────────────
mkdir -p /app
chown ec2-user:ec2-user /app

# ── systemd template unit (포트별 인스턴스 관리) ──────────────
cat > /etc/systemd/system/tonefit@.service << 'SERVICEEOF'
[Unit]
Description=ToneFit Spring Boot Application (port %i)
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/app
ExecStart=/usr/bin/java -jar /app/app-%i.jar
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tonefit-%i
Environment=SPRING_PROFILES_ACTIVE=prod
Environment=DB_HOST=${db_host}
Environment=DB_PORT=${db_port}

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
# 초기 JAR가 없으므로 enable만 — 첫 배포 시 deploy.sh가 기동
systemctl enable tonefit@8080.service

# ── Blue/Green 배포 스크립트 ───────────────────────────────────
cat > /app/deploy.sh << 'DEPLOYEOF'
#!/bin/bash
set -e

REGION="ap-northeast-2"
S3_BUCKET="tonefit-prod-server"
NGINX_CONF="/etc/nginx/conf.d/tonefit.conf"

# S3에서 새 JAR 다운로드
aws s3 cp s3://$S3_BUCKET/app.jar /app/app-new.jar --region $REGION
echo "JAR downloaded from S3"

# 현재 활성 포트 확인
CURRENT=$(grep -oP '127\.0\.0\.1:\K\d+' $NGINX_CONF)
if [ "$CURRENT" = "8080" ]; then
    NEW_PORT=8081; OLD_PORT=8080
else
    NEW_PORT=8080; OLD_PORT=8081
fi

echo "Switching: $OLD_PORT → $NEW_PORT"

# 새 슬롯에 JAR 배치 후 기동
cp /app/app-new.jar /app/app-$NEW_PORT.jar
chown ec2-user:ec2-user /app/app-$NEW_PORT.jar
systemctl start tonefit@$NEW_PORT

# 헬스체크 (최대 60초)
for i in {1..60}; do
    if curl -sf http://localhost:$NEW_PORT/actuator/health > /dev/null 2>&1; then
        echo "Health check passed on port $NEW_PORT"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "Health check failed — rolling back"
        systemctl stop tonefit@$NEW_PORT
        exit 1
    fi
    sleep 1
done

# Nginx upstream 교체 (graceful reload)
sed -i "s/127\.0\.0\.1:$OLD_PORT/127.0.0.1:$NEW_PORT/" $NGINX_CONF
nginx -t && nginx -s reload
echo "Nginx switched to port $NEW_PORT"

# 구버전 드레이닝 후 종료
sleep 5
systemctl stop tonefit@$OLD_PORT

echo "Deployment complete: active port is $NEW_PORT"
DEPLOYEOF

chmod +x /app/deploy.sh
chown ec2-user:ec2-user /app/deploy.sh

# ── CloudWatch Agent ───────────────────────────────────────────
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/tonefit/prod/nginx/access",
            "log_stream_name": "{instance_id}",
            "timezone": "Local"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/tonefit/prod/nginx/error",
            "log_stream_name": "{instance_id}",
            "timezone": "Local"
          }
        ]
      },
      "journald": {
        "collect_list": [
          {
            "log_group_name": "/tonefit/prod/app",
            "log_stream_name": "{instance_id}",
            "units": ["tonefit@8080.service", "tonefit@8081.service"]
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
