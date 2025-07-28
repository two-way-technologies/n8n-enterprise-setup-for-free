#!/bin/bash

# ────────────────────────────────
# n8n Stack Health Check Script
# ────────────────────────────────

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            ;;
    esac
}

echo "🔍 n8n Stack Health Check"
echo "=========================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_status "ERROR" "Docker is not running"
    exit 1
fi
print_status "OK" "Docker is running"

# Check if containers are running
containers=("n8n_postgres" "n8n_redis" "n8n_app" "nginx_proxy_manager")
for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        print_status "OK" "Container $container is running"
    else
        print_status "ERROR" "Container $container is not running"
    fi
done

# Check container health
echo ""
echo "🏥 Container Health Status"
echo "========================="
for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | grep -q "healthy"; then
        print_status "OK" "$container is healthy"
    elif docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | grep -q "unhealthy"; then
        print_status "ERROR" "$container is unhealthy"
    else
        print_status "WARN" "$container health status unknown"
    fi
done

# Check service endpoints
echo ""
echo "🌐 Service Endpoint Check"
echo "========================="

# Check n8n
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 | grep -q "200"; then
    print_status "OK" "n8n is accessible on port 5678"
else
    print_status "ERROR" "n8n is not accessible on port 5678"
fi

# Check Nginx Proxy Manager
if curl -s -o /dev/null -w "%{http_code}" http://localhost:81 | grep -q "200"; then
    print_status "OK" "Nginx Proxy Manager is accessible on port 81"
else
    print_status "ERROR" "Nginx Proxy Manager is not accessible on port 81"
fi

# Check PostgreSQL
if docker exec n8n_postgres pg_isready -U n8n-postgres > /dev/null 2>&1; then
    print_status "OK" "PostgreSQL is accepting connections"
else
    print_status "ERROR" "PostgreSQL is not accepting connections"
fi

# Check Redis
if docker exec n8n_redis redis-cli ping > /dev/null 2>&1; then
    print_status "OK" "Redis is responding"
else
    print_status "ERROR" "Redis is not responding"
fi

# Check disk usage
echo ""
echo "💾 Disk Usage"
echo "============="
df -h | grep -E "(Filesystem|/dev/)" | head -2

# Check Docker volumes
echo ""
echo "📦 Docker Volumes"
echo "================="
docker volume ls | grep n8n-supermani-ai

echo ""
echo "Health check completed!"
