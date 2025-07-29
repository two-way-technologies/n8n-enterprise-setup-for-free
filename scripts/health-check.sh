#!/bin/bash

# n8n Health Check Script
# Comprehensive health monitoring for n8n Docker setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker compose.yaml"

echo -e "${BLUE}=== n8n Health Check ===${NC}"
echo "Project Directory: $PROJECT_DIR"
echo "Compose File: $COMPOSE_FILE"
echo ""

# Function to print status
print_status() {
    local service=$1
    local status=$2
    local message=$3
    
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC} $service: $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $service: $message"
    else
        echo -e "${RED}✗${NC} $service: $message"
    fi
}

# Check Docker and Docker Compose
echo -e "${BLUE}1. Docker Environment${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_status "Docker" "OK" "$DOCKER_VERSION"
else
    print_status "Docker" "ERROR" "Docker not found"
    exit 1
fi

if command -v docker compose &> /dev/null; then
    COMPOSE_VERSION=$(docker compose --version)
    print_status "Docker Compose" "OK" "$COMPOSE_VERSION"
else
    print_status "Docker Compose" "ERROR" "Docker Compose not found"
    exit 1
fi

echo ""

# Check container status
echo -e "${BLUE}2. Container Status${NC}"
cd "$PROJECT_DIR"

# Get container status
N8N_STATUS=$(docker compose ps -q n8n 2>/dev/null | xargs docker inspect --format='{{.State.Status}}' 2>/dev/null || echo "not_found")
NGINX_STATUS=$(docker compose ps -q nginx 2>/dev/null | xargs docker inspect --format='{{.State.Status}}' 2>/dev/null || echo "not_found")

if [ "$N8N_STATUS" = "running" ]; then
    print_status "n8n Main" "OK" "Container running"
else
    print_status "n8n Main" "ERROR" "Container not running (status: $N8N_STATUS)"
fi

if [ "$NGINX_STATUS" = "running" ]; then
    print_status "Nginx" "OK" "Container running"
else
    print_status "Nginx" "ERROR" "Container not running (status: $NGINX_STATUS)"
fi

echo ""

# Check service health
echo -e "${BLUE}3. Service Health${NC}"

# Check n8n direct access
if curl -f -s -o /dev/null http://localhost:5678; then
    print_status "n8n Direct" "OK" "Accessible on port 5678"
else
    print_status "n8n Direct" "ERROR" "Not accessible on port 5678"
fi

# Check nginx proxy
if curl -f -s -o /dev/null http://localhost:80; then
    print_status "Nginx Proxy" "OK" "Accessible on port 80"
else
    print_status "Nginx Proxy" "ERROR" "Not accessible on port 80"
fi

# Check nginx health endpoint
if curl -f -s -o /dev/null http://localhost:80/nginx-health; then
    print_status "Nginx Health" "OK" "Health endpoint responding"
else
    print_status "Nginx Health" "WARNING" "Health endpoint not responding"
fi

echo ""

# Check database connectivity
echo -e "${BLUE}4. Database Connectivity${NC}"
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
    
    # Test PostgreSQL connection
    if [ -n "$DB_POSTGRESDB_HOST" ] && [ -n "$DB_POSTGRESDB_PORT" ]; then
        if (echo > /dev/tcp/$DB_POSTGRESDB_HOST/$DB_POSTGRESDB_PORT) 2>/dev/null; then
            print_status "PostgreSQL" "OK" "Connection to $DB_POSTGRESDB_HOST:$DB_POSTGRESDB_PORT successful"
        else
            print_status "PostgreSQL" "ERROR" "Cannot connect to $DB_POSTGRESDB_HOST:$DB_POSTGRESDB_PORT"
        fi
    else
        print_status "PostgreSQL" "WARNING" "Database configuration not found"
    fi
    
    # Test Redis connection (if queue mode is enabled)
    if [ "$EXECUTIONS_MODE" = "queue" ] && [ -n "$QUEUE_BULL_REDIS_HOST" ] && [ -n "$QUEUE_BULL_REDIS_PORT" ]; then
        if (echo > /dev/tcp/$QUEUE_BULL_REDIS_HOST/$QUEUE_BULL_REDIS_PORT) 2>/dev/null; then
            print_status "Redis" "OK" "Connection to $QUEUE_BULL_REDIS_HOST:$QUEUE_BULL_REDIS_PORT successful"
        else
            print_status "Redis" "ERROR" "Cannot connect to $QUEUE_BULL_REDIS_HOST:$QUEUE_BULL_REDIS_PORT"
        fi
    else
        print_status "Redis" "WARNING" "Queue mode disabled or Redis configuration not found"
    fi
else
    print_status "Configuration" "ERROR" ".env file not found"
fi

echo ""

# Check logs for errors
echo -e "${BLUE}5. Recent Logs Analysis${NC}"
if [ "$N8N_STATUS" = "running" ]; then
    ERROR_COUNT=$(docker compose logs n8n --tail=50 2>/dev/null | grep -i error | wc -l)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_status "n8n Logs" "OK" "No recent errors found"
    else
        print_status "n8n Logs" "WARNING" "$ERROR_COUNT error(s) found in recent logs"
    fi
else
    print_status "n8n Logs" "ERROR" "Cannot check logs - container not running"
fi

echo ""

# Resource usage
echo -e "${BLUE}6. Resource Usage${NC}"
if [ "$N8N_STATUS" = "running" ]; then
    N8N_CONTAINER_ID=$(docker compose ps -q n8n)
    if [ -n "$N8N_CONTAINER_ID" ]; then
        STATS=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" "$N8N_CONTAINER_ID" | tail -n 1)
        print_status "n8n Resources" "OK" "CPU/Memory: $STATS"
    fi
fi

echo ""

# Summary
echo -e "${BLUE}=== Health Check Summary ===${NC}"
if [ "$N8N_STATUS" = "running" ] && curl -f -s -o /dev/null http://localhost:5678; then
    echo -e "${GREEN}✓ n8n is healthy and accessible${NC}"
    echo "  - Web Interface: http://localhost:5678"
    echo "  - Nginx Proxy: http://localhost:80"
else
    echo -e "${RED}✗ n8n has issues that need attention${NC}"
    echo "  - Check container logs: docker compose logs n8n"
    echo "  - Restart services: docker compose restart"
fi

echo ""
echo "For detailed logs, run: docker compose logs"
echo "To restart services, run: docker compose restart"
