#!/bin/bash

# ────────────────────────────────
# n8n Horizontal Scaling Management Script
# ────────────────────────────────

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yaml"
SERVICE_NAME="n8n-worker"
DEFAULT_REPLICAS=3
MAX_REPLICAS=10
MIN_REPLICAS=1

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
    esac
}

# Function to get current replica count
get_current_replicas() {
    docker-compose ps -q $SERVICE_NAME | wc -l | tr -d ' '
}

# Function to scale workers
scale_workers() {
    local target_replicas=$1
    
    if [ "$target_replicas" -lt $MIN_REPLICAS ]; then
        print_status "ERROR" "Minimum replicas is $MIN_REPLICAS"
        exit 1
    fi
    
    if [ "$target_replicas" -gt $MAX_REPLICAS ]; then
        print_status "ERROR" "Maximum replicas is $MAX_REPLICAS"
        exit 1
    fi
    
    print_status "INFO" "Scaling $SERVICE_NAME to $target_replicas replicas..."
    
    # Update environment variable
    sed -i.bak "s/N8N_WORKER_REPLICAS=.*/N8N_WORKER_REPLICAS=$target_replicas/" .env
    
    # Scale the service
    docker-compose up -d --scale $SERVICE_NAME=$target_replicas
    
    # Wait for services to be healthy
    print_status "INFO" "Waiting for services to become healthy..."
    sleep 10
    
    # Check health
    local healthy_count=0
    local max_wait=60
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        healthy_count=$(docker-compose ps $SERVICE_NAME | grep "healthy" | wc -l | tr -d ' ')
        if [ "$healthy_count" -eq "$target_replicas" ]; then
            break
        fi
        sleep 5
        wait_time=$((wait_time + 5))
        print_status "INFO" "Waiting... ($healthy_count/$target_replicas healthy)"
    done
    
    if [ "$healthy_count" -eq "$target_replicas" ]; then
        print_status "OK" "Successfully scaled to $target_replicas healthy replicas"
    else
        print_status "WARN" "Only $healthy_count/$target_replicas replicas are healthy"
    fi
}

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 n8n Scaling Status${NC}"
    echo "======================"
    
    local current_replicas=$(get_current_replicas)
    print_status "INFO" "Current worker replicas: $current_replicas"
    
    echo ""
    echo "Container Status:"
    docker-compose ps
    
    echo ""
    echo "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    echo ""
    echo "Queue Status (Redis):"
    docker exec n8n_redis redis-cli -a "${REDIS_PASSWORD:-n8n_redis_secure_pass_2024}" info replication 2>/dev/null || echo "Redis not accessible"
}

# Function to auto-scale based on queue length
auto_scale() {
    print_status "INFO" "Checking queue metrics for auto-scaling..."
    
    # Get queue length from Redis
    local queue_length=$(docker exec n8n_redis redis-cli -a "${REDIS_PASSWORD:-n8n_redis_secure_pass_2024}" llen "bull:n8n:waiting" 2>/dev/null || echo "0")
    local current_replicas=$(get_current_replicas)
    
    print_status "INFO" "Queue length: $queue_length, Current replicas: $current_replicas"
    
    # Auto-scaling logic
    if [ "$queue_length" -gt 100 ] && [ "$current_replicas" -lt $MAX_REPLICAS ]; then
        local new_replicas=$((current_replicas + 1))
        print_status "WARN" "High queue length detected. Scaling up to $new_replicas replicas"
        scale_workers $new_replicas
    elif [ "$queue_length" -lt 10 ] && [ "$current_replicas" -gt $MIN_REPLICAS ]; then
        local new_replicas=$((current_replicas - 1))
        print_status "INFO" "Low queue length detected. Scaling down to $new_replicas replicas"
        scale_workers $new_replicas
    else
        print_status "OK" "No scaling needed"
    fi
}

# Function to show help
show_help() {
    echo "n8n Horizontal Scaling Management"
    echo "================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  scale <number>    Scale workers to specific number of replicas"
    echo "  up               Scale up by 1 replica"
    echo "  down             Scale down by 1 replica"
    echo "  status           Show current scaling status"
    echo "  auto             Auto-scale based on queue metrics"
    echo "  reset            Reset to default replica count ($DEFAULT_REPLICAS)"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 scale 5       # Scale to 5 worker replicas"
    echo "  $0 up            # Add 1 worker replica"
    echo "  $0 down          # Remove 1 worker replica"
    echo "  $0 status        # Show current status"
    echo "  $0 auto          # Auto-scale based on queue"
    echo ""
    echo "Limits:"
    echo "  Minimum replicas: $MIN_REPLICAS"
    echo "  Maximum replicas: $MAX_REPLICAS"
}

# Main script logic
case "${1:-help}" in
    "scale")
        if [ -z "$2" ]; then
            print_status "ERROR" "Please specify number of replicas"
            echo "Usage: $0 scale <number>"
            exit 1
        fi
        scale_workers $2
        ;;
    "up")
        current=$(get_current_replicas)
        new_count=$((current + 1))
        scale_workers $new_count
        ;;
    "down")
        current=$(get_current_replicas)
        new_count=$((current - 1))
        scale_workers $new_count
        ;;
    "status")
        show_status
        ;;
    "auto")
        auto_scale
        ;;
    "reset")
        scale_workers $DEFAULT_REPLICAS
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        print_status "ERROR" "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
