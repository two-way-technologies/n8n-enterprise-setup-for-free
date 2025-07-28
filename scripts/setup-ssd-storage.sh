#!/bin/bash

# ────────────────────────────────────────────────────────────────────────────────
# n8n SSD Storage Setup Script for GCP c2-standard-4 Instance
# ────────────────────────────────────────────────────────────────────────────────
# This script prepares the 100GB SSD storage for optimal n8n deployment
# Run this script before starting the Docker Compose stack
# ────────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SSD_BASE_PATH="/opt/n8n/ssd-storage"
DOCKER_USER_ID="1000"
DOCKER_GROUP_ID="1000"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to create directory with proper permissions
create_directory() {
    local dir_path="$1"
    local owner="$2"
    local permissions="$3"
    
    if [[ ! -d "$dir_path" ]]; then
        print_status "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        chown "$owner" "$dir_path"
        chmod "$permissions" "$dir_path"
        print_success "Created $dir_path with permissions $permissions"
    else
        print_warning "Directory already exists: $dir_path"
        chown "$owner" "$dir_path"
        chmod "$permissions" "$dir_path"
    fi
}

# Function to setup SSD storage structure
setup_ssd_storage() {
    print_status "Setting up SSD storage structure at $SSD_BASE_PATH"
    
    # Create base directory
    create_directory "$SSD_BASE_PATH" "root:root" "755"
    
    # Create n8n data directories
    create_directory "$SSD_BASE_PATH/n8n-data" "$DOCKER_USER_ID:$DOCKER_GROUP_ID" "755"
    create_directory "$SSD_BASE_PATH/logs" "$DOCKER_USER_ID:$DOCKER_GROUP_ID" "755"
    create_directory "$SSD_BASE_PATH/custom" "$DOCKER_USER_ID:$DOCKER_GROUP_ID" "755"
    create_directory "$SSD_BASE_PATH/binary-data" "$DOCKER_USER_ID:$DOCKER_GROUP_ID" "755"
    create_directory "$SSD_BASE_PATH/worker-data" "$DOCKER_USER_ID:$DOCKER_GROUP_ID" "755"
    
    # Create Redis data directory
    create_directory "$SSD_BASE_PATH/redis-data" "999:999" "755"
    create_directory "$SSD_BASE_PATH/redis" "999:999" "755"
    
    # Create Nginx data directories
    create_directory "$SSD_BASE_PATH/nginx-data" "root:root" "755"
    create_directory "$SSD_BASE_PATH/letsencrypt" "root:root" "755"
    create_directory "$SSD_BASE_PATH/nginx" "root:root" "755"
    
    # Create monitoring data directories
    create_directory "$SSD_BASE_PATH/prometheus-data" "65534:65534" "755"
    create_directory "$SSD_BASE_PATH/grafana-data" "472:472" "755"
    create_directory "$SSD_BASE_PATH/prometheus" "65534:65534" "755"
    create_directory "$SSD_BASE_PATH/grafana" "472:472" "755"
    
    print_success "SSD storage structure created successfully"
}

# Function to optimize SSD settings
optimize_ssd() {
    print_status "Optimizing SSD settings for performance"
    
    # Check if the SSD mount point exists
    if mountpoint -q "$SSD_BASE_PATH"; then
        print_status "SSD is properly mounted at $SSD_BASE_PATH"
    else
        print_warning "SSD may not be mounted at $SSD_BASE_PATH"
        print_warning "Please ensure your 100GB SSD is mounted at this location"
    fi
    
    # Set optimal mount options (if remounting is needed)
    print_status "Recommended SSD mount options:"
    echo "  - noatime: Disable access time updates"
    echo "  - discard: Enable TRIM support"
    echo "  - defaults: Standard mount options"
    echo ""
    echo "Example fstab entry:"
    echo "/dev/sdb1 $SSD_BASE_PATH ext4 defaults,noatime,discard 0 2"
}

# Function to create backup directories
setup_backup_structure() {
    print_status "Setting up backup directory structure"
    
    create_directory "$SSD_BASE_PATH/backups" "root:root" "755"
    create_directory "$SSD_BASE_PATH/backups/daily" "root:root" "755"
    create_directory "$SSD_BASE_PATH/backups/weekly" "root:root" "755"
    create_directory "$SSD_BASE_PATH/backups/monthly" "root:root" "755"
    
    print_success "Backup directory structure created"
}

# Function to set up log rotation
setup_log_rotation() {
    print_status "Setting up log rotation configuration"
    
    cat > /etc/logrotate.d/n8n-docker << 'EOF'
/opt/n8n/ssd-storage/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 1000 1000
    postrotate
        docker kill --signal="USR1" n8n_main 2>/dev/null || true
        docker kill --signal="USR1" n8n_worker 2>/dev/null || true
    endscript
}
EOF
    
    print_success "Log rotation configured for n8n logs"
}

# Function to display storage information
display_storage_info() {
    print_status "Storage Information:"
    echo ""
    df -h "$SSD_BASE_PATH" 2>/dev/null || echo "SSD not yet mounted at $SSD_BASE_PATH"
    echo ""
    print_status "Directory structure:"
    tree "$SSD_BASE_PATH" 2>/dev/null || ls -la "$SSD_BASE_PATH"
}

# Function to create systemd service for automatic setup
create_systemd_service() {
    print_status "Creating systemd service for n8n storage setup"
    
    cat > /etc/systemd/system/n8n-storage-setup.service << EOF
[Unit]
Description=n8n SSD Storage Setup
Before=docker.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=$PWD/scripts/setup-ssd-storage.sh --auto
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable n8n-storage-setup.service
    
    print_success "Systemd service created and enabled"
}

# Main execution
main() {
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                    n8n SSD Storage Setup for GCP c2-standard-4"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    check_root
    
    # Check for auto mode
    if [[ "${1:-}" == "--auto" ]]; then
        print_status "Running in automatic mode"
    else
        print_status "Setting up SSD storage for n8n deployment"
        echo ""
        read -p "Continue with SSD storage setup? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Setup cancelled by user"
            exit 0
        fi
    fi
    
    setup_ssd_storage
    optimize_ssd
    setup_backup_structure
    setup_log_rotation
    
    if [[ "${1:-}" != "--auto" ]]; then
        create_systemd_service
    fi
    
    display_storage_info
    
    echo ""
    print_success "SSD storage setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Ensure your 100GB SSD is mounted at $SSD_BASE_PATH"
    echo "2. Update GCP CloudSQL connection details in .env file"
    echo "3. Run: docker-compose up -d"
    echo ""
    print_warning "Remember to configure your GCP CloudSQL database connection in .env:"
    echo "  - GCP_CLOUDSQL_HOST=your-cloudsql-instance-ip"
    echo "  - POSTGRES_USER=n8n-postgres"
    echo "  - POSTGRES_PASSWORD=your-secure-password"
    echo "  - POSTGRES_DB=n8n-postgres"
}

# Execute main function
main "$@"
