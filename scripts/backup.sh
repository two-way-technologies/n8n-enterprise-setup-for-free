#!/bin/bash

# ────────────────────────────────
# n8n Stack Backup Script
# ────────────────────────────────

set -e

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="n8n_backup_$DATE"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔄 Starting n8n Stack Backup${NC}"
echo "=================================="

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup PostgreSQL database
echo -e "${YELLOW}📊 Backing up PostgreSQL database...${NC}"
docker exec n8n_postgres pg_dump -U n8n-postgres -d n8n-postgres > "$BACKUP_DIR/$BACKUP_NAME/postgres_dump.sql"

# Backup n8n data volume
echo -e "${YELLOW}📁 Backing up n8n data volume...${NC}"
docker run --rm -v n8n-supermani-ai_n8n_data:/data -v "$(pwd)/$BACKUP_DIR/$BACKUP_NAME":/backup alpine tar czf /backup/n8n_data.tar.gz -C /data .

# Backup n8n logs volume
echo -e "${YELLOW}📋 Backing up n8n logs...${NC}"
docker run --rm -v n8n-supermani-ai_n8n_logs:/data -v "$(pwd)/$BACKUP_DIR/$BACKUP_NAME":/backup alpine tar czf /backup/n8n_logs.tar.gz -C /data .

# Backup Nginx Proxy Manager data
echo -e "${YELLOW}🌐 Backing up Nginx Proxy Manager data...${NC}"
docker run --rm -v n8n-supermani-ai_npm_data:/data -v "$(pwd)/$BACKUP_DIR/$BACKUP_NAME":/backup alpine tar czf /backup/npm_data.tar.gz -C /data .

# Backup SSL certificates
echo -e "${YELLOW}🔒 Backing up SSL certificates...${NC}"
docker run --rm -v n8n-supermani-ai_npm_letsencrypt:/data -v "$(pwd)/$BACKUP_DIR/$BACKUP_NAME":/backup alpine tar czf /backup/ssl_certs.tar.gz -C /data .

# Backup configuration files
echo -e "${YELLOW}⚙️ Backing up configuration files...${NC}"
cp docker-compose.yaml "$BACKUP_DIR/$BACKUP_NAME/"
cp .env "$BACKUP_DIR/$BACKUP_NAME/env_backup"
cp -r postgres/ "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true
cp -r nginx/ "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true

# Create backup info file
cat > "$BACKUP_DIR/$BACKUP_NAME/backup_info.txt" << EOF
n8n Stack Backup Information
============================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Docker Compose Version: $(docker-compose --version)
Docker Version: $(docker --version)

Included in this backup:
- PostgreSQL database dump
- n8n data volume
- n8n logs volume
- Nginx Proxy Manager data
- SSL certificates
- Configuration files (docker-compose.yaml, .env)
- Custom configurations

To restore this backup, use the restore.sh script.
EOF

# Create compressed archive
echo -e "${YELLOW}📦 Creating compressed archive...${NC}"
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd ..

# Cleanup old backups (keep last 7 days)
echo -e "${YELLOW}🧹 Cleaning up old backups...${NC}"
find "$BACKUP_DIR" -name "n8n_backup_*.tar.gz" -mtime +7 -delete

echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo "Backup saved as: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "Backup size: $(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)"
