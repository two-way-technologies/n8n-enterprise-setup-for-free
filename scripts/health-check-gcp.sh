#!/bin/bash

# ────────────────────────────────────────────────────────────────────────────────
# n8n Health Check Script for GCP c2-standard-4 with External CloudSQL
# ────────────────────────────────────────────────────────────────────────────────
# This script performs comprehensive health checks optimized for the new configuration
# ────────────────────────────────────────────────────────────────────────────────

set -euo pipefail

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
ENV_FILE="$PROJECT_DIR/.env"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to check SSD storage
check_ssd_storage() {
    print_status "Checking SSD storage..."
    
    local ssd_path="/opt/n8n/ssd-storage"
    if [[ ! -d "$ssd_path" ]]; then
        print_error "SSD storage directory not found: $ssd_path"
        return 1
    fi
    
    if mountpoint -q "$ssd_path" 2>/dev/null; then
        print_success "SSD storage is properly mounted at $ssd_path"
    else
        print_warning "SSD storage may not be mounted at $ssd_path"
    fi
    
    local usage
    usage=$(df "$ssd_path" | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    if [[ "$usage" -lt 80 ]]; then
        print_success "SSD usage: ${usage}% (OK)"
    elif [[ "$usage" -lt 90 ]]; then
        print_warning "SSD usage: ${usage}% (Warning)"
    else
        print_error "SSD usage: ${usage}% (Critical)"
        return 1
    fi
}

# Function to check external GCP CloudSQL PostgreSQL
check_external_postgres() {
    print_status "Checking external GCP CloudSQL PostgreSQL..."
    
    if [[ -z "${GCP_CLOUDSQL_HOST:-}" ]]; then
        print_error "GCP_CLOUDSQL_HOST not configured in .env file"
        return 1
    fi
    
    local n8n_container
    n8n_container=$(docker-compose -f "$COMPOSE_FILE" ps -q n8n-main 2>/dev/null)
    
    if [[ -z "$n8n_container" ]]; then
        print_error "n8n main container not found"
        return 1
    fi
    
    if docker exec "$n8n_container" pg_isready -h "${GCP_CLOUDSQL_HOST}" -p "${GCP_CLOUDSQL_PORT:-5432}" -U "${POSTGRES_USER:-n8n-postgres}" >/dev/null 2>&1; then
        print_success "GCP CloudSQL PostgreSQL is accepting connections"
    else
        print_error "Cannot connect to GCP CloudSQL PostgreSQL at ${GCP_CLOUDSQL_HOST}"
        return 1
    fi
}

# Function to check Redis and queue metrics
check_redis_queue() {
    print_status "Checking Redis and queue metrics..."
    
    local redis_container
    redis_container=$(docker-compose -f "$COMPOSE_FILE" ps -q redis 2>/dev/null)
    
    if [[ -z "$redis_container" ]]; then
        print_error "Redis container not found"
        return 1
    fi
    
    if docker exec "$redis_container" redis-cli -a "${REDIS_PASSWORD:-}" ping >/dev/null 2>&1; then
        print_success "Redis is responding to ping"
        
        local queue_length
        queue_length=$(docker exec "$redis_container" redis-cli -a "${REDIS_PASSWORD:-}" llen "bull:n8n:waiting" 2>/dev/null || echo "0")
        print_success "Redis queue length: $queue_length jobs waiting"
        
        local memory_usage
        memory_usage=$(docker exec "$redis_container" redis-cli -a "${REDIS_PASSWORD:-}" info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
        print_success "Redis memory usage: $memory_usage"
    else
        print_error "Redis is not responding"
        return 1
    fi
}

# Function to check n8n workers optimized for c2-standard-4
check_n8n_workers() {
    print_status "Checking n8n worker instances (c2-standard-4 optimized)..."
    
    local worker_containers
    worker_containers=$(docker-compose -f "$COMPOSE_FILE" ps -q n8n-worker 2>/dev/null)
    
    if [[ -z "$worker_containers" ]]; then
        print_error "No n8n worker containers found"
        return 1
    fi
    
    local worker_count
    worker_count=$(echo "$worker_containers" | wc -l)
    print_success "Found $worker_count n8n worker instance(s)"
    
    local healthy_workers=0
    while IFS= read -r container_id; do
        if [[ -n "$container_id" ]]; then
            local health
            health=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "unknown")
            if [[ "$health" == "healthy" ]]; then
                ((healthy_workers++))
            fi
        fi
    done <<< "$worker_containers"
    
    print_success "$healthy_workers/$worker_count worker instances are healthy"
    
    local expected_replicas="${N8N_WORKER_REPLICAS:-4}"
    if [[ "$worker_count" -eq "$expected_replicas" ]]; then
        print_success "Worker count matches expected replicas ($expected_replicas)"
    else
        print_warning "Worker count ($worker_count) differs from expected replicas ($expected_replicas)"
    fi
}

# Function to check resource usage for c2-standard-4
check_c2_standard_4_resources() {
    print_status "Checking resource usage (c2-standard-4: 4 vCPUs, 16GB RAM)..."
    
    # Check memory usage (16GB total)
    local mem_info
    mem_info=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    
    if (( $(echo "$mem_info < 75" | bc -l) )); then
        print_success "Memory usage: ${mem_info}% (Optimal for c2-standard-4)"
    elif (( $(echo "$mem_info < 85" | bc -l) )); then
        print_warning "Memory usage: ${mem_info}% (High but acceptable)"
    else
        print_error "Memory usage: ${mem_info}% (Critical - consider scaling down)"
        return 1
    fi
    
    # Check CPU load (4 cores)
    local cpu_load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    if (( $(echo "$cpu_load < 3.0" | bc -l) )); then
        print_success "CPU load: $cpu_load (Optimal for 4 cores)"
    elif (( $(echo "$cpu_load < 4.0" | bc -l) )); then
        print_warning "CPU load: $cpu_load (High but manageable)"
    else
        print_error "CPU load: $cpu_load (Critical - system overloaded)"
        return 1
    fi
    
    # Check container resource usage
    print_status "Container resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10
}

# Function to check all services
check_all_services() {
    print_status "Checking all service health..."
    
    local services=("redis" "n8n-main" "n8n-worker" "nginx-proxy-manager" "prometheus" "grafana" "redis-exporter")
    local failed_services=0
    
    for service in "${services[@]}"; do
        local status
        status=$(docker-compose -f "$COMPOSE_FILE" ps -q "$service" 2>/dev/null)
        
        if [[ -z "$status" ]]; then
            print_error "$service is not running"
            ((failed_services++))
        else
            local health
            health=$(docker inspect --format='{{.State.Health.Status}}' "$status" 2>/dev/null || echo "no-health-check")
            
            case "$health" in
                "healthy")
                    print_success "$service is healthy"
                    ;;
                "unhealthy")
                    print_error "$service is unhealthy"
                    ((failed_services++))
                    ;;
                "starting")
                    print_warning "$service is starting"
                    ;;
                "no-health-check")
                    print_warning "$service has no health check configured"
                    ;;
                *)
                    print_warning "$service health status: $health"
                    ;;
            esac
        fi
    done
    
    if [[ $failed_services -eq 0 ]]; then
        print_success "All services are running properly"
    else
        print_error "$failed_services service(s) have issues"
        return 1
    fi
}

# Function to check endpoints
check_endpoints() {
    print_status "Checking service endpoints..."
    
    # Check n8n main
    if curl -f -s http://localhost:5678/healthz >/dev/null 2>&1; then
        print_success "n8n main instance is responding"
    else
        print_error "n8n main instance is not responding on port 5678"
        return 1
    fi
    
    # Check Nginx Proxy Manager
    if curl -f -s http://localhost:81/api/schema >/dev/null 2>&1; then
        print_success "Nginx Proxy Manager is responding"
    else
        print_error "Nginx Proxy Manager is not responding on port 81"
        return 1
    fi
    
    # Check Prometheus
    if curl -f -s http://localhost:9090/-/healthy >/dev/null 2>&1; then
        print_success "Prometheus is healthy"
    else
        print_error "Prometheus is not responding"
        return 1
    fi
    
    # Check Grafana
    if curl -f -s http://localhost:3000/api/health >/dev/null 2>&1; then
        print_success "Grafana is healthy"
    else
        print_error "Grafana is not responding"
        return 1
    fi
}

# Main health check function
run_comprehensive_health_check() {
    local failed_checks=0
    
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "           n8n Health Check for GCP c2-standard-4 with External CloudSQL"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Infrastructure checks
    check_ssd_storage || ((failed_checks++))
    check_c2_standard_4_resources || ((failed_checks++))
    
    echo ""
    # Service checks
    check_all_services || ((failed_checks++))
    check_external_postgres || ((failed_checks++))
    check_redis_queue || ((failed_checks++))
    check_n8n_workers || ((failed_checks++))
    
    echo ""
    # Endpoint checks
    check_endpoints || ((failed_checks++))
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    
    if [[ $failed_checks -eq 0 ]]; then
        print_success "All health checks passed! 🎉"
        echo ""
        print_status "Service URLs:"
        echo "  • n8n Interface: http://localhost:5678"
        echo "  • Nginx Proxy Manager: http://localhost:81"
        echo "  • Grafana: http://localhost:3000"
        echo "  • Prometheus: http://localhost:9090"
        echo ""
        print_status "Configuration Summary:"
        echo "  • Instance Type: GCP c2-standard-4 (4 vCPUs, 16GB RAM)"
        echo "  • Database: External GCP CloudSQL PostgreSQL"
        echo "  • Workers: ${N8N_WORKER_REPLICAS:-4} instances"
        echo "  • Storage: 100GB SSD at /opt/n8n/ssd-storage"
        return 0
    else
        print_error "$failed_checks health check(s) failed"
        echo ""
        print_status "For detailed logs, run:"
        echo "  docker-compose logs [service-name]"
        return 1
    fi
}

# Execute main function
main() {
    cd "$PROJECT_DIR"
    run_comprehensive_health_check
}

main "$@"
