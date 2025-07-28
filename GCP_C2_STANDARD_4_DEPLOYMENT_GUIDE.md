# n8n Production Deployment Guide for GCP c2-standard-4

## 🚀 Overview

This guide provides step-by-step instructions for deploying a production-ready n8n automation platform on a GCP c2-standard-4 instance (4 vCPUs, 16GB RAM, 100GB SSD) with external CloudSQL PostgreSQL database.

## 🏗️ Architecture

### Infrastructure Components
- **GCP c2-standard-4 Instance**: 4 vCPUs, 16GB RAM, 100GB SSD
- **External GCP CloudSQL PostgreSQL**: n8n-postgres database
- **Redis Queue Management**: High-performance job distribution
- **Nginx Load Balancer**: SSL termination and traffic distribution
- **Horizontal Scaling**: 4 worker instances optimized for CPU cores
- **Monitoring Stack**: Prometheus + Grafana + Redis Exporter

### Resource Allocation (Optimized for c2-standard-4)
```
Total Resources: 4 vCPUs, 16GB RAM
├── n8n Main Instance: 2.0 vCPUs, 6GB RAM
├── n8n Workers (4x): 1.0 vCPU, 3GB RAM each
├── Redis: 1.0 vCPU, 2.5GB RAM
├── Nginx: 1.0 vCPU, 1.5GB RAM
├── Prometheus: 0.5 vCPU, 1GB RAM
├── Grafana: 0.5 vCPU, 768MB RAM
└── Redis Exporter: 0.2 vCPU, 256MB RAM
```

## 📋 Prerequisites

### 1. GCP CloudSQL PostgreSQL Setup
```sql
-- Create database and user
CREATE DATABASE "n8n-postgres";
CREATE USER "n8n-postgres" WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE "n8n-postgres" TO "n8n-postgres";
```

### 2. GCP Instance Configuration
- **Instance Type**: c2-standard-4
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 100GB SSD persistent disk
- **Network**: Allow HTTP/HTTPS traffic

### 3. Required Software
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install additional tools
sudo apt install tree htop curl wget -y
```

## 🔧 Installation Steps

### Step 1: Clone Repository
```bash
git clone https://github.com/MilesEducation-Tech/n8n-supermani-ai.git
cd n8n-supermani-ai
```

### Step 2: Configure SSD Storage
```bash
# Mount 100GB SSD (adjust device as needed)
sudo mkfs.ext4 /dev/sdb
sudo mkdir -p /opt/n8n/ssd-storage
sudo mount /dev/sdb /opt/n8n/ssd-storage

# Add to fstab for persistent mounting
echo '/dev/sdb /opt/n8n/ssd-storage ext4 defaults,noatime,discard 0 2' | sudo tee -a /etc/fstab

# Setup storage structure
sudo ./scripts/setup-ssd-storage.sh
```

### Step 3: Configure Environment Variables
```bash
# Copy and edit environment file
cp .env.example .env
nano .env
```

**Required Configuration:**
```bash
# GCP CloudSQL Configuration
GCP_CLOUDSQL_HOST=your-cloudsql-instance-ip
GCP_CLOUDSQL_PORT=5432
GCP_CLOUDSQL_SSL_MODE=require
POSTGRES_USER=n8n-postgres
POSTGRES_PASSWORD=your-secure-password
POSTGRES_DB=n8n-postgres

# Redis Configuration
REDIS_PASSWORD=your-secure-redis-password

# n8n Configuration
N8N_HOST=your-domain.com
N8N_PROTOCOL=https
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password
N8N_ENCRYPTION_KEY=your-32-character-encryption-key

# Scaling Configuration (Optimized for c2-standard-4)
N8N_WORKER_REPLICAS=4
N8N_WORKERS_CONCURRENCY=15
```

### Step 4: Deploy the Stack
```bash
# Start all services
docker-compose up -d

# Verify deployment
docker-compose ps
./scripts/health-check.sh
```

## 🔒 Security Configuration

### 1. Firewall Rules
```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow from 10.0.0.0/8 to any port 5432  # CloudSQL access
```

### 2. SSL Certificate Setup
1. Access Nginx Proxy Manager: `http://your-server-ip:81`
2. Login: `admin@example.com` / `changeme`
3. Add SSL certificate for your domain
4. Configure proxy host for n8n

### 3. Database Security
- Use strong passwords for all database users
- Enable SSL connections to CloudSQL
- Configure IP whitelisting for CloudSQL access
- Regular security updates

## 📊 Monitoring & Maintenance

### Access Points
| Service | URL | Credentials |
|---------|-----|-------------|
| **n8n Interface** | https://your-domain.com | admin / your-password |
| **Nginx Proxy Manager** | http://your-server-ip:81 | admin@example.com / changeme |
| **Grafana** | http://your-server-ip:3000 | admin / your-grafana-password |
| **Prometheus** | http://your-server-ip:9090 | No authentication |

### Performance Monitoring
```bash
# Real-time monitoring
./scripts/monitor-performance.sh monitor

# Check scaling status
./scripts/scale-n8n.sh status

# View resource usage
docker stats

# Check logs
docker-compose logs -f n8n-main
```

### Scaling Operations
```bash
# Scale workers based on load
./scripts/scale-n8n.sh scale 6    # Scale to 6 workers
./scripts/scale-n8n.sh auto       # Auto-scale based on queue

# Manual scaling
docker-compose up -d --scale n8n-worker=6
```

## 🔄 Backup & Recovery

### Automated Backups
```bash
# Run backup script
./scripts/backup.sh

# Schedule daily backups
echo "0 2 * * * /path/to/n8n-supermani-ai/scripts/backup.sh" | sudo crontab -
```

### Manual Backup
```bash
# Backup volumes
docker run --rm -v n8n_data:/data -v /opt/n8n/ssd-storage/backups:/backup alpine tar czf /backup/n8n-data-$(date +%Y%m%d).tar.gz -C /data .

# Backup database (CloudSQL)
gcloud sql export sql your-instance-name gs://your-bucket/n8n-backup-$(date +%Y%m%d).sql --database=n8n-postgres
```

## 🚨 Troubleshooting

### Common Issues

1. **High Memory Usage**
   ```bash
   # Check memory usage
   docker stats
   # Adjust worker replicas
   ./scripts/scale-n8n.sh scale 3
   ```

2. **Database Connection Issues**
   ```bash
   # Test CloudSQL connectivity
   docker exec n8n_main pg_isready -h $GCP_CLOUDSQL_HOST -p 5432 -U n8n-postgres
   ```

3. **Queue Backlog**
   ```bash
   # Check Redis queue
   docker exec n8n_redis redis-cli -a $REDIS_PASSWORD llen bull:n8n:waiting
   # Scale up workers
   ./scripts/scale-n8n.sh up
   ```

### Log Analysis
```bash
# View aggregated logs
docker-compose logs --tail=100 -f

# Check specific service
docker-compose logs n8n-main
docker-compose logs redis
```

## 📈 Performance Optimization

### For High-Volume Workloads
1. **Increase worker concurrency**: Adjust `N8N_WORKERS_CONCURRENCY`
2. **Scale workers**: Use auto-scaling based on queue metrics
3. **Optimize database**: Tune CloudSQL instance size
4. **Monitor resources**: Use Grafana dashboards

### Resource Tuning
```bash
# Monitor queue metrics
./scripts/monitor-performance.sh redis

# Check database connections
./scripts/monitor-performance.sh postgres

# View container resources
./scripts/monitor-performance.sh containers
```

## 🎯 Production Checklist

- [ ] GCP CloudSQL PostgreSQL configured and accessible
- [ ] 100GB SSD mounted and optimized
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Firewall rules configured
- [ ] Monitoring dashboards setup
- [ ] Backup strategy implemented
- [ ] Log rotation configured
- [ ] Health checks passing
- [ ] Performance testing completed

## 📞 Support

For issues and support:
1. Check logs: `docker-compose logs [service]`
2. Run health check: `./scripts/health-check.sh`
3. Monitor performance: `./scripts/monitor-performance.sh all`
4. Review documentation and troubleshooting guides

---

**🎉 Congratulations!** Your production-ready n8n deployment is now optimized for the GCP c2-standard-4 instance with horizontal scaling capabilities.
