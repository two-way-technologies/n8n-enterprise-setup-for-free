#!/bin/bash

# n8n Scaled Deployment Script
# Automated deployment with scaling capabilities

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

echo -e "${BLUE}=== n8n Scaled Deployment ===${NC}"
echo "Project Directory: $PROJECT_DIR"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

# Check prerequisites
echo -e "${BLUE}1. Checking Prerequisites${NC}"

if command -v docker &> /dev/null; then
    print_status "OK" "Docker is installed"
else
    print_status "ERROR" "Docker not found. Please install Docker first."
    exit 1
fi

if command -v docker compose &> /dev/null; then
    print_status "OK" "Docker Compose is installed"
else
    print_status "ERROR" "Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

if [ -f "$PROJECT_DIR/.env" ]; then
    print_status "OK" "Environment configuration found"
else
    print_status "ERROR" ".env file not found. Please create it first."
    exit 1
fi

echo ""

# Stop existing containers
echo -e "${BLUE}2. Stopping Existing Containers${NC}"
cd "$PROJECT_DIR"

if docker compose ps -q | grep -q .; then
    print_status "OK" "Stopping existing containers..."
    docker compose down
else
    print_status "OK" "No existing containers to stop"
fi

echo ""

# Pull latest images
echo -e "${BLUE}3. Pulling Latest Images${NC}"
print_status "OK" "Pulling n8n:latest..."
docker compose pull

echo ""

# Start services
echo -e "${BLUE}4. Starting Services${NC}"
print_status "OK" "Starting n8n main instance..."
docker compose up -d n8n

# Wait for n8n to be healthy
echo "Waiting for n8n to be healthy..."
TIMEOUT=120
COUNTER=0

while [ $COUNTER -lt $TIMEOUT ]; do
    if docker compose ps n8n | grep -q "healthy"; then
        print_status "OK" "n8n main instance is healthy"
        break
    fi
    
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo "Waiting... ($COUNTER/$TIMEOUT seconds)"
    fi
    
    sleep 1
    COUNTER=$((COUNTER + 1))
done

if [ $COUNTER -ge $TIMEOUT ]; then
    print_status "ERROR" "n8n failed to become healthy within $TIMEOUT seconds"
    echo "Checking logs..."
    docker compose logs n8n --tail=20
    exit 1
fi

# Start nginx
print_status "OK" "Starting nginx load balancer..."
docker compose up -d nginx

echo ""

# Verify deployment
echo -e "${BLUE}5. Verifying Deployment${NC}"

# Check if services are accessible
sleep 5

if curl -f -s -o /dev/null http://localhost:5678; then
    print_status "OK" "n8n is accessible on port 5678"
else
    print_status "ERROR" "n8n is not accessible on port 5678"
fi

if curl -f -s -o /dev/null http://localhost:80; then
    print_status "OK" "Nginx proxy is accessible on port 80"
else
    print_status "ERROR" "Nginx proxy is not accessible on port 80"
fi

echo ""

# Display status
echo -e "${BLUE}6. Deployment Status${NC}"
docker compose ps

echo ""

# Success message
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo "🚀 n8n is now running!"
echo ""
echo "Access URLs:"
echo "  • n8n Web Interface: http://localhost:5678"
echo "  • Nginx Load Balancer: http://localhost:80"
echo ""
echo "Management Commands:"
echo "  • View logs: docker compose logs"
echo "  • Stop services: docker compose down"
echo "  • Restart services: docker compose restart"
echo "  • Health check: ./scripts/health-check.sh"
echo ""

# Check if workers are enabled
source "$PROJECT_DIR/.env"
if [ "$N8N_WORKERS_ENABLED" = "true" ]; then
    echo -e "${YELLOW}Note: Worker scaling is available but currently disabled.${NC}"
    echo "To enable workers with queue mode:"
    echo "  1. Set EXECUTIONS_MODE=queue in .env"
    echo "  2. Set N8N_WORKERS_ENABLED=true in .env"
    echo "  3. Uncomment n8n-worker service in docker compose.yaml"
    echo "  4. Run: docker compose up -d"
    echo ""
fi

echo "Deployment completed successfully! 🎉"
