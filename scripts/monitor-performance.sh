#!/bin/bash

# n8n Performance Monitoring Script
# Monitor system performance, Redis, and n8n metrics

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
    echo "Usage: $0 {monitor|redis|all|logs}"
    echo ""
    echo "Commands:"
    echo "  monitor     Real-time performance monitoring"
    echo "  redis       Redis-specific metrics"
    echo "  all         Show all available metrics"
    echo "  logs        Show recent logs with error analysis"
    echo ""
    echo "Examples:"
    echo "  $0 monitor  # Start real-time monitoring"
    echo "  $0 redis    # Show Redis metrics"
    echo "  $0 all      # Show comprehensive metrics"
}

# Function to get container stats
get_container_stats() {
    local service=$1
    cd "$PROJECT_DIR"
    
    local container_id=$(docker-compose ps -q "$service" 2>/dev/null)
    if [ -n "$container_id" ]; then
        docker stats --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$container_id" 2>/dev/null
    else
        echo "N/A\tN/A\tN/A\tN/A"
    fi
}

# Function to monitor performance in real-time
monitor_performance() {
    echo -e "${BLUE}=== Real-time Performance Monitor ===${NC}"
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    cd "$PROJECT_DIR"
    
    while true; do
        clear
        echo -e "${BLUE}=== n8n Performance Dashboard ===${NC}"
        echo "$(date)"
        echo ""
        
        # Container status
        echo -e "${BLUE}Container Status:${NC}"
        printf "%-15s %-10s %-15s %-20s %-15s\n" "Service" "Status" "CPU" "Memory" "Network I/O"
        printf "%-15s %-10s %-15s %-20s %-15s\n" "-------" "------" "---" "------" "-----------"
        
        # n8n main
        local n8n_status=$(docker-compose ps n8n 2>/dev/null | grep -v "Name" | awk '{print $4}' || echo "Down")
        local n8n_stats=$(get_container_stats "n8n")
        printf "%-15s %-10s %s\n" "n8n" "$n8n_status" "$n8n_stats" | awk '{printf "%-15s %-10s %-15s %-20s %-15s\n", $1, $2, $3, $4, $5}'
        
        # nginx
        local nginx_status=$(docker-compose ps nginx 2>/dev/null | grep -v "Name" | awk '{print $4}' || echo "Down")
        local nginx_stats=$(get_container_stats "nginx")
        printf "%-15s %-10s %s\n" "nginx" "$nginx_status" "$nginx_stats" | awk '{printf "%-15s %-10s %-15s %-20s %-15s\n", $1, $2, $3, $4, $5}'
        
        # Workers (if any)
        local worker_count=$(docker-compose ps -q n8n-worker 2>/dev/null | wc -l)
        if [ "$worker_count" -gt 0 ]; then
            printf "%-15s %-10s %-15s %-20s %-15s\n" "workers" "$worker_count active" "..." "..." "..."
        fi
        
        echo ""
        
        # Service health
        echo -e "${BLUE}Service Health:${NC}"
        if curl -f -s -o /dev/null http://localhost:5678; then
            print_status "OK" "n8n Web Interface (port 5678)"
        else
            print_status "ERROR" "n8n Web Interface (port 5678)"
        fi
        
        if curl -f -s -o /dev/null http://localhost:80; then
            print_status "OK" "Nginx Proxy (port 80)"
        else
            print_status "ERROR" "Nginx Proxy (port 80)"
        fi
        
        echo ""
        
        # System resources
        echo -e "${BLUE}System Resources:${NC}"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2 " (" $3/$2*100 "% used)"}')"
        echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
        
        echo ""
        echo "Refreshing in 5 seconds... (Ctrl+C to stop)"
        sleep 5
    done
}

# Function to show Redis metrics
show_redis_metrics() {
    echo -e "${BLUE}=== Redis Metrics ===${NC}"
    
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        
        if [ "$EXECUTIONS_MODE" = "queue" ]; then
            echo "Queue Mode: Enabled"
            echo "Redis Host: ${QUEUE_BULL_REDIS_HOST:-Not configured}"
            echo "Redis Port: ${QUEUE_BULL_REDIS_PORT:-Not configured}"
            echo ""
            
            # Test Redis connectivity
            if [ -n "$QUEUE_BULL_REDIS_HOST" ] && [ -n "$QUEUE_BULL_REDIS_PORT" ]; then
                if (echo > /dev/tcp/$QUEUE_BULL_REDIS_HOST/$QUEUE_BULL_REDIS_PORT) 2>/dev/null; then
                    print_status "OK" "Redis connection successful"
                    
                    # Try to get Redis info (would need redis-cli for detailed metrics)
                    echo ""
                    echo "Note: For detailed Redis metrics, install redis-cli and configure authentication"
                    echo "Example commands:"
                    echo "  redis-cli -h $QUEUE_BULL_REDIS_HOST -p $QUEUE_BULL_REDIS_PORT info"
                    echo "  redis-cli -h $QUEUE_BULL_REDIS_HOST -p $QUEUE_BULL_REDIS_PORT client list"
                else
                    print_status "ERROR" "Cannot connect to Redis"
                fi
            else
                print_status "WARNING" "Redis configuration incomplete"
            fi
        else
            echo "Queue Mode: Disabled (using regular execution mode)"
            print_status "WARNING" "Redis metrics not available in regular mode"
        fi
    else
        print_status "ERROR" ".env file not found"
    fi
}

# Function to show all metrics
show_all_metrics() {
    echo -e "${BLUE}=== Comprehensive Metrics ===${NC}"
    echo ""
    
    # Container status
    echo -e "${BLUE}1. Container Status${NC}"
    cd "$PROJECT_DIR"
    docker-compose ps
    echo ""
    
    # Resource usage
    echo -e "${BLUE}2. Resource Usage${NC}"
    local containers=$(docker-compose ps -q 2>/dev/null)
    if [ -n "$containers" ]; then
        docker stats --no-stream $containers
    else
        echo "No containers running"
    fi
    echo ""
    
    # Service health
    echo -e "${BLUE}3. Service Health${NC}"
    if curl -f -s -o /dev/null http://localhost:5678; then
        print_status "OK" "n8n accessible on port 5678"
    else
        print_status "ERROR" "n8n not accessible on port 5678"
    fi
    
    if curl -f -s -o /dev/null http://localhost:80; then
        print_status "OK" "Nginx accessible on port 80"
    else
        print_status "ERROR" "Nginx not accessible on port 80"
    fi
    echo ""
    
    # Database connectivity
    echo -e "${BLUE}4. Database Connectivity${NC}"
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        
        if [ -n "$DB_POSTGRESDB_HOST" ] && [ -n "$DB_POSTGRESDB_PORT" ]; then
            if (echo > /dev/tcp/$DB_POSTGRESDB_HOST/$DB_POSTGRESDB_PORT) 2>/dev/null; then
                print_status "OK" "PostgreSQL connection successful"
            else
                print_status "ERROR" "PostgreSQL connection failed"
            fi
        fi
    fi
    echo ""
    
    # Redis metrics
    show_redis_metrics
    echo ""
    
    # System info
    echo -e "${BLUE}5. System Information${NC}"
    echo "Uptime: $(uptime)"
    echo "Load: $(cat /proc/loadavg)"
    echo "Memory: $(free -h | grep '^Mem:')"
    echo "Disk: $(df -h / | tail -1)"
}

# Function to analyze logs
analyze_logs() {
    echo -e "${BLUE}=== Log Analysis ===${NC}"
    
    cd "$PROJECT_DIR"
    
    echo -e "${BLUE}Recent n8n logs (last 50 lines):${NC}"
    docker-compose logs n8n --tail=50
    echo ""
    
    echo -e "${BLUE}Error Analysis:${NC}"
    local error_count=$(docker-compose logs n8n --tail=100 2>/dev/null | grep -i error | wc -l)
    local warning_count=$(docker-compose logs n8n --tail=100 2>/dev/null | grep -i warning | wc -l)
    
    echo "Errors in last 100 log lines: $error_count"
    echo "Warnings in last 100 log lines: $warning_count"
    
    if [ "$error_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}Recent Errors:${NC}"
        docker-compose logs n8n --tail=100 2>/dev/null | grep -i error | tail -5
    fi
    
    if [ "$warning_count" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Recent Warnings:${NC}"
        docker-compose logs n8n --tail=100 2>/dev/null | grep -i warning | tail -5
    fi
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    monitor)
        monitor_performance
        ;;
    
    redis)
        show_redis_metrics
        ;;
    
    all)
        show_all_metrics
        ;;
    
    logs)
        analyze_logs
        ;;
    
    *)
        echo "Error: Unknown command '$1'"
        show_usage
        exit 1
        ;;
esac
