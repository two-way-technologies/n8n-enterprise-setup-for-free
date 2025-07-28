#!/bin/bash

# ────────────────────────────────
# n8n Performance Monitoring Script
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
REDIS_PASSWORD="${REDIS_PASSWORD:-n8n_redis_secure_pass_2024}"
MONITORING_INTERVAL=5
LOG_FILE="./logs/performance_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory
mkdir -p logs

# Function to print colored output
print_metric() {
    local label=$1
    local value=$2
    local unit=$3
    local color=$4
    echo -e "${color}${label}:${NC} ${value}${unit}"
}

# Function to get Redis metrics
get_redis_metrics() {
    local redis_info=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" info 2>/dev/null)
    
    # Queue metrics
    local waiting_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:waiting" 2>/dev/null || echo "0")
    local active_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:active" 2>/dev/null || echo "0")
    local completed_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:completed" 2>/dev/null || echo "0")
    local failed_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:failed" 2>/dev/null || echo "0")
    
    # Memory usage
    local used_memory=$(echo "$redis_info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local used_memory_peak=$(echo "$redis_info" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    
    # Connection metrics
    local connected_clients=$(echo "$redis_info" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    local total_connections=$(echo "$redis_info" | grep "total_connections_received:" | cut -d: -f2 | tr -d '\r')
    
    echo -e "${CYAN}📊 Redis Queue Metrics${NC}"
    echo "======================"
    print_metric "Waiting Jobs" "$waiting_jobs" "" "$YELLOW"
    print_metric "Active Jobs" "$active_jobs" "" "$GREEN"
    print_metric "Completed Jobs" "$completed_jobs" "" "$BLUE"
    print_metric "Failed Jobs" "$failed_jobs" "" "$RED"
    print_metric "Memory Used" "$used_memory" "" "$CYAN"
    print_metric "Peak Memory" "$used_memory_peak" "" "$CYAN"
    print_metric "Connected Clients" "$connected_clients" "" "$GREEN"
    print_metric "Total Connections" "$total_connections" "" "$BLUE"
}

# Function to get PostgreSQL metrics
get_postgres_metrics() {
    local pg_stats=$(docker exec n8n_postgres psql -U n8n-postgres -d n8n-postgres -t -c "
        SELECT 
            (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
            (SELECT count(*) FROM pg_stat_activity) as total_connections,
            (SELECT setting FROM pg_settings WHERE name = 'max_connections') as max_connections;
    " 2>/dev/null || echo "0|0|0")
    
    local active_conn=$(echo "$pg_stats" | cut -d'|' -f1 | tr -d ' ')
    local total_conn=$(echo "$pg_stats" | cut -d'|' -f2 | tr -d ' ')
    local max_conn=$(echo "$pg_stats" | cut -d'|' -f3 | tr -d ' ')
    
    # Database size
    local db_size=$(docker exec n8n_postgres psql -U n8n-postgres -d n8n-postgres -t -c "
        SELECT pg_size_pretty(pg_database_size('n8n-postgres'));
    " 2>/dev/null | tr -d ' ' || echo "Unknown")
    
    echo -e "${CYAN}🗄️ PostgreSQL Metrics${NC}"
    echo "======================"
    print_metric "Active Connections" "$active_conn" "/$max_conn" "$GREEN"
    print_metric "Total Connections" "$total_conn" "/$max_conn" "$BLUE"
    print_metric "Database Size" "$db_size" "" "$CYAN"
}

# Function to get container metrics
get_container_metrics() {
    echo -e "${CYAN}🐳 Container Resource Usage${NC}"
    echo "============================"
    
    # Get stats for all n8n containers
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | grep -E "(n8n|redis|postgres)" || echo "No containers found"
}

# Function to get n8n execution metrics
get_execution_metrics() {
    # Try to get metrics from n8n API (if available)
    local n8n_health=$(curl -s -u "admin:SuperSecureUIpass!" http://localhost:5678/healthz 2>/dev/null || echo "unavailable")
    
    echo -e "${CYAN}⚡ n8n Execution Metrics${NC}"
    echo "========================"
    print_metric "Main Instance Health" "$n8n_health" "" "$GREEN"
    
    # Worker health checks
    local worker_count=$(docker-compose ps -q n8n-worker | wc -l | tr -d ' ')
    print_metric "Worker Instances" "$worker_count" "" "$BLUE"
    
    # Check worker health
    local healthy_workers=0
    for container in $(docker-compose ps -q n8n-worker); do
        local health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "unknown")
        if [ "$health" = "healthy" ]; then
            healthy_workers=$((healthy_workers + 1))
        fi
    done
    
    print_metric "Healthy Workers" "$healthy_workers" "/$worker_count" "$GREEN"
}

# Function to get system metrics
get_system_metrics() {
    echo -e "${CYAN}💻 System Metrics${NC}"
    echo "=================="
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    print_metric "CPU Usage" "$cpu_usage" "%" "$YELLOW"
    
    # Memory usage
    local mem_info=$(free -h | grep "Mem:")
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_total=$(echo $mem_info | awk '{print $2}')
    print_metric "Memory Usage" "$mem_used/$mem_total" "" "$YELLOW"
    
    # Disk usage
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    print_metric "Disk Usage" "$disk_usage" "" "$YELLOW"
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    print_metric "Load Average" "$load_avg" "" "$CYAN"
}

# Function to log metrics
log_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get key metrics for logging
    local waiting_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:waiting" 2>/dev/null || echo "0")
    local active_jobs=$(docker exec n8n_redis redis-cli -a "$REDIS_PASSWORD" llen "bull:n8n:active" 2>/dev/null || echo "0")
    local worker_count=$(docker-compose ps -q n8n-worker | wc -l | tr -d ' ')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    echo "$timestamp,waiting_jobs:$waiting_jobs,active_jobs:$active_jobs,workers:$worker_count,cpu:$cpu_usage" >> "$LOG_FILE"
}

# Function to show real-time monitoring
monitor_realtime() {
    echo -e "${GREEN}🔄 Starting Real-time Performance Monitoring${NC}"
    echo "=============================================="
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    while true; do
        clear
        echo -e "${GREEN}n8n Performance Dashboard - $(date)${NC}"
        echo "=================================================="
        echo ""
        
        get_redis_metrics
        echo ""
        get_postgres_metrics
        echo ""
        get_execution_metrics
        echo ""
        get_container_metrics
        echo ""
        get_system_metrics
        
        # Log metrics
        log_metrics
        
        echo ""
        echo -e "${BLUE}📝 Logging to: $LOG_FILE${NC}"
        echo -e "${YELLOW}⏱️ Next update in $MONITORING_INTERVAL seconds...${NC}"
        
        sleep $MONITORING_INTERVAL
    done
}

# Function to show help
show_help() {
    echo "n8n Performance Monitoring Script"
    echo "================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  monitor          Start real-time monitoring dashboard"
    echo "  redis            Show Redis/Queue metrics"
    echo "  postgres         Show PostgreSQL metrics"
    echo "  containers       Show container resource usage"
    echo "  executions       Show n8n execution metrics"
    echo "  system           Show system metrics"
    echo "  all              Show all metrics once"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 monitor       # Start real-time dashboard"
    echo "  $0 redis         # Show queue metrics"
    echo "  $0 all           # Show all metrics"
}

# Main script logic
case "${1:-all}" in
    "monitor")
        monitor_realtime
        ;;
    "redis")
        get_redis_metrics
        ;;
    "postgres")
        get_postgres_metrics
        ;;
    "containers")
        get_container_metrics
        ;;
    "executions")
        get_execution_metrics
        ;;
    "system")
        get_system_metrics
        ;;
    "all")
        get_redis_metrics
        echo ""
        get_postgres_metrics
        echo ""
        get_execution_metrics
        echo ""
        get_container_metrics
        echo ""
        get_system_metrics
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
