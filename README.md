# n8n Automation Platform - Horizontally Scalable Setup

## 🚀 Overview

This is a production-ready, horizontally scalable Docker Compose setup for n8n automation platform. It features queue-based execution, load balancing, monitoring, and can handle thousands of concurrent workflow executions across multiple worker instances.

## 🏗️ Scalable Architecture

```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │ (Nginx Proxy)   │
                    │  Port 80/443    │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   n8n Main      │
                    │   Instance      │
                    │  (Port 5678)    │
                    └─────────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼───────┐    ┌────────▼────────┐    ┌──────▼──────┐
│  n8n Worker   │    │   n8n Worker    │    │ n8n Worker  │
│   Instance    │    │    Instance     │    │  Instance   │
│   (Scalable)  │    │   (Scalable)    │    │ (Scalable)  │
└───────┬───────┘    └────────┬────────┘    └──────┬──────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼───────┐
                    │  Redis Queue    │
                    │   Management    │
                    │  (Port 6379)    │
                    └─────────┬───────┘
                              │
                    ┌─────────▼───────┐
                    │   PostgreSQL    │
                    │    Database     │
                    │  (Port 5432)    │
                    └─────────────────┘

        ┌─────────────────┐    ┌─────────────────┐
        │   Prometheus    │    │    Grafana      │
        │   Monitoring    │    │   Dashboard     │
        │  (Port 9090)    │    │  (Port 3000)    │
        └─────────────────┘    └─────────────────┘
```

## 📋 Features

### ⚡ Horizontal Scaling
- **Multiple n8n worker instances** for parallel execution
- **Queue-based execution** with Redis for job distribution
- **Load balancing** with Nginx for high availability
- **Auto-scaling capabilities** based on queue metrics
- **Resource optimization** for high-volume operations

### 🚀 Performance Optimizations
- **Redis queue management** for distributed execution
- **Optimized PostgreSQL** with connection pooling
- **Resource limits** and CPU/memory reservations
- **Health checks** for all services
- **Comprehensive logging** with rotation

### 🔒 Security Enhancements
- **Network isolation** between services
- **Environment variables** for sensitive data
- **SSL/TLS support** via Nginx Proxy Manager
- **Security headers** and rate limiting
- **Proper authentication** and encryption

### 📊 Monitoring & Observability
- **Prometheus metrics** collection
- **Grafana dashboards** for visualization
- **Real-time performance** monitoring
- **Queue metrics** and execution tracking
- **Resource usage** monitoring

### 🛠️ Production Features
- **Automatic restarts** and health recovery
- **Data persistence** with named volumes
- **Backup and restore** automation
- **Scaling management** scripts
- **Deployment automation**

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB+ RAM available (8GB+ recommended for scaling)
- 20GB+ disk space
- Multi-core CPU (4+ cores recommended)

### 1. Deploy Scaled Infrastructure
```bash
# Automated deployment with scaling
./scripts/deploy-scaled.sh

# Or manual deployment
docker compose up -d
```

### 2. Scale Workers
```bash
# Scale to 5 worker instances
./scripts/scale-n8n.sh scale 5

# Auto-scale based on queue metrics
./scripts/scale-n8n.sh auto

# Check scaling status
./scripts/scale-n8n.sh status
```

### 3. Monitor Performance
```bash
# Real-time performance dashboard
./scripts/monitor-performance.sh monitor

# Check specific metrics
./scripts/monitor-performance.sh redis
./scripts/monitor-performance.sh all
```

### 4. Access Services
- **n8n Interface**: http://localhost:5678
- **Nginx Proxy Manager**: http://localhost:81
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_HOST` | Domain for n8n | `2way.tech` |
| `N8N_PROTOCOL` | Protocol (http/https) | `https` |
| `POSTGRES_USER` | Database username | `n8n-postgres` |
| `POSTGRES_PASSWORD` | Database password | *required* |
| `N8N_ENCRYPTION_KEY` | Encryption key (32+ chars) | *required* |
| `REDIS_PASSWORD` | Redis password | *auto-generated* |

## 🏥 Health Monitoring

### Health Check Script
```bash
# Run comprehensive health check
./scripts/health-check.sh
```

## 💾 Backup & Restore

### Create Backup
```bash
# Create full backup
./scripts/backup.sh
```

## 🔍 Troubleshooting

### Common Issues

#### n8n Won't Start
```bash
# Check database connection
docker compose logs postgres

# Check n8n logs
docker compose logs n8n

# Restart services
docker compose restart
```

#### Database Connection Issues
```bash
# Check PostgreSQL health
docker exec n8n_postgres pg_isready -U n8n-postgres

# Reset database
docker compose down -v
docker compose up -d
```

## 🛡️ Security

### SSL/HTTPS Setup
1. Access Nginx Proxy Manager at http://localhost:81
2. Default login: admin@example.com / changeme
3. Add proxy host for your domain
4. Configure SSL certificate (Let's Encrypt)

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Docker logs
3. Run health check script