#!/bin/bash

# n8n Scaling Management Script
# Scale n8n workers up/down and manage auto-scaling

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
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yaml"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 {scale|status|auto|stop}"
    echo ""
    echo "Commands:"
    echo "  scale <number>  Scale workers to specified number"
    echo "  status          Show current scaling status"
    echo "  auto            Enable auto-scaling (placeholder)"
    echo "  stop            Stop all workers"
    echo ""
    echo "Examples:"
    echo "  $0 scale 3      # Scale to 3 workers"
    echo "  $0 status       # Show current status"
    echo "  $0 stop         # Stop all workers"
}

# Function to check if queue mode is enabled
check_queue_mode() {
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        if [ "$EXECUTIONS_MODE" != "queue" ]; then
            print_status "ERROR" "Queue mode is not enabled. Set EXECUTIONS_MODE=queue in .env"
            echo "To enable queue mode:"
            echo "1. Edit .env file: EXECUTIONS_MODE=queue"
            echo "2. Set N8N_WORKERS_ENABLED=true"
            echo "3. Uncomment n8n-worker service in docker-compose.yaml"
            echo "4. Restart: docker-compose restart"
            return 1
        fi
    else
        print_status "ERROR" ".env file not found"
        return 1
    fi
    return 0
}

# Function to get current worker count
get_worker_count() {
    cd "$PROJECT_DIR"
    docker-compose ps -q n8n-worker 2>/dev/null | wc -l
}

# Function to scale workers
scale_workers() {
    local target_count=$1
    
    if ! [[ "$target_count" =~ ^[0-9]+$ ]] || [ "$target_count" -lt 0 ]; then
        print_status "ERROR" "Invalid worker count: $target_count"
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    echo -e "${BLUE}=== Scaling n8n Workers ===${NC}"
    echo "Target worker count: $target_count"
    
    # Check if workers are commented out in docker-compose.yaml
    if grep -q "^# n8n-worker:" "$COMPOSE_FILE"; then
        print_status "WARNING" "n8n-worker service is commented out in docker-compose.yaml"
        echo "Please uncomment the n8n-worker service first."
        return 1
    fi
    
    if [ "$target_count" -eq 0 ]; then
        print_status "OK" "Stopping all workers..."
        docker-compose stop n8n-worker 2>/dev/null || true
        docker-compose rm -f n8n-worker 2>/dev/null || true
    else
        print_status "OK" "Scaling to $target_count workers..."
        docker-compose up -d --scale n8n-worker="$target_count" n8n-worker
        
        # Wait a moment for containers to start
        sleep 3
        
        # Verify scaling
        actual_count=$(get_worker_count)
        if [ "$actual_count" -eq "$target_count" ]; then
            print_status "OK" "Successfully scaled to $actual_count workers"
        else
            print_status "WARNING" "Scaling may not be complete. Current: $actual_count, Target: $target_count"
        fi
    fi
}

# Function to show status
show_status() {
    echo -e "${BLUE}=== n8n Scaling Status ===${NC}"
    
    cd "$PROJECT_DIR"
    
    # Check if queue mode is enabled
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        echo "Execution Mode: $EXECUTIONS_MODE"
        echo "Workers Enabled: ${N8N_WORKERS_ENABLED:-false}"
        echo ""
    fi
    
    # Show main instance status
    N8N_STATUS=$(docker-compose ps n8n 2>/dev/null | grep -v "Name" | awk '{print $4}' || echo "Not running")
    echo "Main Instance: $N8N_STATUS"
    
    # Show worker status
    WORKER_COUNT=$(get_worker_count)
    echo "Active Workers: $WORKER_COUNT"
    
    if [ "$WORKER_COUNT" -gt 0 ]; then
        echo ""
        echo "Worker Details:"
        docker-compose ps n8n-worker 2>/dev/null || echo "No workers found"
    fi
    
    echo ""
    
    # Show resource usage if containers are running
    if [ "$WORKER_COUNT" -gt 0 ]; then
        echo "Resource Usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose ps -q n8n-worker 2>/dev/null) 2>/dev/null || echo "Unable to get resource stats"
    fi
}

# Function for auto-scaling (placeholder)
auto_scale() {
    echo -e "${BLUE}=== Auto-scaling (Placeholder) ===${NC}"
    print_status "WARNING" "Auto-scaling is not yet implemented"
    echo ""
    echo "Auto-scaling would monitor:"
    echo "  • Queue length"
    echo "  • CPU/Memory usage"
    echo "  • Response times"
    echo "  • Active executions"
    echo ""
    echo "For now, use manual scaling with: $0 scale <number>"
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    scale)
        if [ $# -ne 2 ]; then
            echo "Error: scale command requires a number"
            echo "Usage: $0 scale <number>"
            exit 1
        fi
        
        if ! check_queue_mode; then
            exit 1
        fi
        
        scale_workers "$2"
        ;;
    
    status)
        show_status
        ;;
    
    auto)
        auto_scale
        ;;
    
    stop)
        echo -e "${BLUE}=== Stopping All Workers ===${NC}"
        scale_workers 0
        ;;
    
    *)
        echo "Error: Unknown command '$1'"
        show_usage
        exit 1
        ;;
esac
