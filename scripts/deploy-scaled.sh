#!/bin/bash

# ────────────────────────────────
# n8n Scaled Deployment Script
# ────────────────────────────────

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yaml"
ENV_FILE=".env"
BACKUP_DIR="./backups/pre-scaling-$(date +%Y%m%d_%H%M%S)"

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
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
        "STEP")
            echo -e "${CYAN}🔄${NC} $message"
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "STEP" "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_status "ERROR" "Docker is not installed"
        exit 1
    fi
    print_status "OK" "Docker is available"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_status "ERROR" "Docker Compose is not installed"
        exit 1
    fi
    print_status "OK" "Docker Compose is available"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_status "ERROR" "Docker daemon is not running"
        exit 1
    fi
    print_status "OK" "Docker daemon is running"
    
    # Check available resources
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$total_mem" -lt 4 ]; then
        print_status "WARN" "Less than 4GB RAM available. Scaling may be limited."
    else
        print_status "OK" "Sufficient memory available (${total_mem}GB)"
    fi
    
    # Check disk space
    local disk_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$disk_space" -lt 10 ]; then
        print_status "WARN" "Less than 10GB disk space available"
    else
        print_status "OK" "Sufficient disk space available (${disk_space}GB)"
    fi
}

# Function to create backup
create_backup() {
    print_status "STEP" "Creating backup before scaling deployment..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup configuration files
    cp "$COMPOSE_FILE" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$ENV_FILE" "$BACKUP_DIR/env_backup" 2>/dev/null || true
    
    # Backup existing data if containers are running
    if docker-compose ps | grep -q "Up"; then
        print_status "INFO" "Backing up existing data..."
        ./scripts/backup.sh || print_status "WARN" "Backup script failed, continuing..."
    fi
    
    print_status "OK" "Backup created at $BACKUP_DIR"
}

# Function to validate configuration
validate_configuration() {
    print_status "STEP" "Validating configuration..."
    
    # Check if .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        print_status "ERROR" ".env file not found"
        exit 1
    fi
    print_status "OK" ".env file found"
    
    # Check if docker-compose.yaml exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_status "ERROR" "docker-compose.yaml file not found"
        exit 1
    fi
    print_status "OK" "docker-compose.yaml file found"
    
    # Validate docker-compose syntax
    if ! docker-compose config &> /dev/null; then
        print_status "ERROR" "Invalid docker-compose.yaml syntax"
        exit 1
    fi
    print_status "OK" "Docker Compose configuration is valid"
    
    # Check required environment variables
    source "$ENV_FILE"
    local required_vars=("POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_DB" "N8N_ENCRYPTION_KEY" "REDIS_PASSWORD")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_status "ERROR" "Required environment variable $var is not set"
            exit 1
        fi
    done
    print_status "OK" "All required environment variables are set"
}

# Function to pull latest images
pull_images() {
    print_status "STEP" "Pulling latest Docker images..."
    
    docker-compose pull
    
    print_status "OK" "Latest images pulled successfully"
}

# Function to deploy scaled infrastructure
deploy_infrastructure() {
    print_status "STEP" "Deploying scaled n8n infrastructure..."
    
    # Stop existing services
    print_status "INFO" "Stopping existing services..."
    docker-compose down || true
    
    # Start core services first (database, redis)
    print_status "INFO" "Starting core services (PostgreSQL, Redis)..."
    docker-compose up -d postgres redis
    
    # Wait for core services to be healthy
    print_status "INFO" "Waiting for core services to be healthy..."
    local max_wait=120
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if docker-compose ps postgres | grep -q "healthy" && docker-compose ps redis | grep -q "healthy"; then
            break
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        print_status "INFO" "Waiting for core services... (${wait_time}s)"
    done
    
    if [ $wait_time -ge $max_wait ]; then
        print_status "ERROR" "Core services failed to become healthy"
        exit 1
    fi
    print_status "OK" "Core services are healthy"
    
    # Start n8n main instance
    print_status "INFO" "Starting n8n main instance..."
    docker-compose up -d n8n-main
    
    # Wait for main instance to be healthy
    print_status "INFO" "Waiting for n8n main instance to be healthy..."
    wait_time=0
    while [ $wait_time -lt $max_wait ]; do
        if docker-compose ps n8n-main | grep -q "healthy"; then
            break
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        print_status "INFO" "Waiting for n8n main instance... (${wait_time}s)"
    done
    
    if [ $wait_time -ge $max_wait ]; then
        print_status "ERROR" "n8n main instance failed to become healthy"
        exit 1
    fi
    print_status "OK" "n8n main instance is healthy"
    
    # Start worker instances
    print_status "INFO" "Starting n8n worker instances..."
    docker-compose up -d n8n-worker
    
    # Start monitoring and proxy services
    print_status "INFO" "Starting monitoring and proxy services..."
    docker-compose up -d nginx-proxy-manager prometheus grafana redis-exporter
    
    print_status "OK" "All services deployed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "STEP" "Verifying deployment..."
    
    # Check all services are running
    local services=("postgres" "redis" "n8n-main" "n8n-worker" "nginx-proxy-manager" "prometheus" "grafana")
    
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            print_status "OK" "$service is running"
        else
            print_status "ERROR" "$service is not running"
        fi
    done
    
    # Check health endpoints
    print_status "INFO" "Checking service health endpoints..."
    
    # Wait a bit for services to fully start
    sleep 10
    
    # Check n8n main instance
    if curl -s -f http://localhost:5678/healthz > /dev/null; then
        print_status "OK" "n8n main instance is accessible"
    else
        print_status "WARN" "n8n main instance health check failed"
    fi
    
    # Check Nginx Proxy Manager
    if curl -s -f http://localhost:81 > /dev/null; then
        print_status "OK" "Nginx Proxy Manager is accessible"
    else
        print_status "WARN" "Nginx Proxy Manager health check failed"
    fi
    
    # Check Prometheus
    if curl -s -f http://localhost:9090/-/healthy > /dev/null; then
        print_status "OK" "Prometheus is accessible"
    else
        print_status "WARN" "Prometheus health check failed"
    fi
    
    # Check Grafana
    if curl -s -f http://localhost:3000/api/health > /dev/null; then
        print_status "OK" "Grafana is accessible"
    else
        print_status "WARN" "Grafana health check failed"
    fi
}

# Function to show deployment summary
show_summary() {
    print_status "STEP" "Deployment Summary"
    echo ""
    echo -e "${CYAN}🚀 n8n Scaled Deployment Complete!${NC}"
    echo "===================================="
    echo ""
    echo "Services Access:"
    echo "• n8n Main Instance:     http://localhost:5678"
    echo "• Nginx Proxy Manager:   http://localhost:81"
    echo "• Prometheus:            http://localhost:9090"
    echo "• Grafana:               http://localhost:3000"
    echo ""
    echo "Credentials:"
    echo "• n8n:                   admin / SuperSecureUIpass!"
    echo "• Nginx Proxy Manager:   admin@example.com / changeme"
    echo "• Grafana:               admin / SuperSecureGrafanaPass123!"
    echo ""
    echo "Management Scripts:"
    echo "• Scale workers:         ./scripts/scale-n8n.sh"
    echo "• Monitor performance:   ./scripts/monitor-performance.sh"
    echo "• Health check:          ./scripts/health-check.sh"
    echo ""
    echo "Current Configuration:"
    local worker_count=$(docker-compose ps -q n8n-worker | wc -l | tr -d ' ')
    echo "• Worker instances:      $worker_count"
    echo "• Queue mode:            Enabled (Redis-based)"
    echo "• Load balancing:        Nginx Proxy Manager"
    echo "• Monitoring:            Prometheus + Grafana"
    echo ""
    print_status "OK" "Deployment completed successfully!"
}

# Function to show help
show_help() {
    echo "n8n Scaled Deployment Script"
    echo "============================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --no-backup    Skip backup creation"
    echo "  --help         Show this help message"
    echo ""
    echo "This script will:"
    echo "1. Check prerequisites"
    echo "2. Create backup of existing setup"
    echo "3. Validate configuration"
    echo "4. Pull latest Docker images"
    echo "5. Deploy scaled infrastructure"
    echo "6. Verify deployment"
    echo "7. Show deployment summary"
}

# Main script logic
SKIP_BACKUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main deployment process
echo -e "${GREEN}🚀 Starting n8n Scaled Deployment${NC}"
echo "=================================="
echo ""

check_prerequisites
echo ""

if [ "$SKIP_BACKUP" = false ]; then
    create_backup
    echo ""
fi

validate_configuration
echo ""

pull_images
echo ""

deploy_infrastructure
echo ""

verify_deployment
echo ""

show_summary
