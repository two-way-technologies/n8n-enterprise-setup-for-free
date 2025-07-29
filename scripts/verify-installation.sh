#!/bin/bash

# n8n Superman AI Installation Verification Script
# Verify that your superhero setup is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🦸‍♂️ n8n Superman AI - Installation Verification${NC}"
echo -e "${PURPLE}\"Great power requires great verification!\"${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅${NC} $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️${NC} $message"
    else
        echo -e "${RED}❌${NC} $message"
    fi
}

# Function to test URL accessibility
test_url() {
    local url=$1
    local service_name=$2
    local timeout=${3:-10}
    
    if curl -f -s -m $timeout "$url" > /dev/null 2>&1; then
        print_status "OK" "$service_name is accessible at $url"
        return 0
    else
        print_status "ERROR" "$service_name is NOT accessible at $url"
        return 1
    fi
}

# Check prerequisites
echo -e "${BLUE}🔍 Step 1: Checking Prerequisites${NC}"

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    print_status "OK" "Docker is installed (version: $DOCKER_VERSION)"
else
    print_status "ERROR" "Docker is not installed"
    exit 1
fi

if command -v docker compose &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
    print_status "OK" "Docker Compose is installed (version: $COMPOSE_VERSION)"
else
    print_status "ERROR" "Docker Compose is not installed"
    exit 1
fi

echo ""

# Check environment configuration
echo -e "${BLUE}🔧 Step 2: Environment Configuration${NC}"

if [ -f "$PROJECT_DIR/.env" ]; then
    print_status "OK" "Environment file (.env) exists"
    
    # Check critical environment variables
    source "$PROJECT_DIR/.env"
    
    if [ -n "$N8N_ENCRYPTION_KEY" ] && [ ${#N8N_ENCRYPTION_KEY} -ge 32 ]; then
        print_status "OK" "N8N_ENCRYPTION_KEY is properly configured"
    else
        print_status "ERROR" "N8N_ENCRYPTION_KEY is missing or too short (needs 32+ characters)"
    fi
    
    if [ -n "$POSTGRES_PASSWORD" ]; then
        print_status "OK" "POSTGRES_PASSWORD is configured"
    else
        print_status "WARNING" "POSTGRES_PASSWORD is not set"
    fi
    
else
    print_status "ERROR" "Environment file (.env) not found"
    echo "  💡 Create one from the sample: cp .env_sample .env"
    exit 1
fi

echo ""

# Check Docker services
echo -e "${BLUE}🐳 Step 3: Docker Services Status${NC}"

cd "$PROJECT_DIR"

# Check if services are running
SERVICES=("n8n" "nginx")
ALL_RUNNING=true

for service in "${SERVICES[@]}"; do
    if docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
        print_status "OK" "$service container is running"
    else
        print_status "ERROR" "$service container is not running"
        ALL_RUNNING=false
    fi
done

if [ "$ALL_RUNNING" = false ]; then
    echo ""
    echo -e "${YELLOW}💡 To start services, run: ./scripts/deploy-scaled.sh${NC}"
    exit 1
fi

echo ""

# Test service accessibility
echo -e "${BLUE}🌐 Step 4: Service Accessibility${NC}"

ACCESSIBILITY_OK=true

# Test n8n main interface
if ! test_url "http://localhost:5678" "n8n Main Interface"; then
    ACCESSIBILITY_OK=false
fi

# Test nginx proxy
if ! test_url "http://localhost:80" "Nginx Load Balancer"; then
    ACCESSIBILITY_OK=false
fi

# Test nginx health endpoint
if ! test_url "http://localhost:80/nginx-health" "Nginx Health Check"; then
    ACCESSIBILITY_OK=false
fi

echo ""

# Check worker scaling capability
echo -e "${BLUE}👥 Step 5: Worker Scaling Capability${NC}"

if [ "$EXECUTIONS_MODE" = "queue" ]; then
    print_status "OK" "Queue mode is enabled for scaling"
    
    if [ "$N8N_WORKERS_ENABLED" = "true" ]; then
        print_status "OK" "Workers are enabled"
    else
        print_status "WARNING" "Workers are not enabled (set N8N_WORKERS_ENABLED=true)"
    fi
else
    print_status "WARNING" "Queue mode is not enabled (set EXECUTIONS_MODE=queue for scaling)"
fi

echo ""

# Final verification summary
echo -e "${BLUE}📋 Step 6: Verification Summary${NC}"

if [ "$ALL_RUNNING" = true ] && [ "$ACCESSIBILITY_OK" = true ]; then
    echo -e "${GREEN}🎉 SUCCESS! Your n8n Superman AI setup is working perfectly!${NC}"
    echo ""
    echo -e "${PURPLE}🦸‍♂️ Your automation fortress is ready for action!${NC}"
    echo ""
    echo "🌐 Access your services:"
    echo "  • n8n Interface: http://localhost:5678"
    echo "  • Load Balancer: http://localhost:80"
    echo ""
    echo "🛠️ Management commands:"
    echo "  • Scale workers: ./scripts/scale-n8n.sh scale 3"
    echo "  • Monitor performance: ./scripts/monitor-performance.sh monitor"
    echo "  • Health check: ./scripts/health-check.sh"
    echo ""
    echo -e "${GREEN}\"With great automation comes great responsibility!\" 🚀${NC}"
else
    echo -e "${RED}❌ ISSUES DETECTED! Your setup needs attention.${NC}"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "  1. Check Docker logs: docker compose logs"
    echo "  2. Restart services: docker compose restart"
    echo "  3. Run health check: ./scripts/health-check.sh"
    echo "  4. Check the troubleshooting section in README.md"
    exit 1
fi
