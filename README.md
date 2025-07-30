# 🦸‍♂️ n8n Superman AI - The Ultimate Automation Fortress

<div align="center">

![Superman Logo](https://img.shields.io/badge/🦸‍♂️-Superman%20AI-red?style=for-the-badge&logo=superman&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-FF6D5A?style=for-the-badge&logo=n8n&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-Ready-green)](https://docs.docker.com/compose/)
[![Scalable](https://img.shields.io/badge/Horizontally-Scalable-brightgreen)](https://github.com/2Ways-Technology/n8n-superman-ai)

</div>

---

## 🌟 "With Great Automation Comes Great Responsibility!"

Welcome to **n8n Superman AI** - the most powerful, scalable, and heroic automation platform in the digital universe! Just like Superman protects Metropolis, this fortress of automation safeguards your workflows with unbreakable reliability and lightning-fast performance.

### 🚀 What Makes This Super?

This isn't just another n8n deployment - it's a **production-ready, horizontally scalable automation fortress** that can handle enterprise-level workloads while maintaining the simplicity that makes n8n amazing. Built with the strength of Superman and the intelligence of Lex Luthor's best tech (but used for good!).

### ⚡ Superpowers Included

- **🔥 Horizontal Scaling**: Scale workers like Superman multiplying across dimensions
- **🛡️ Load Balancing**: Nginx-powered traffic distribution stronger than Superman's cape
- **⚡ Queue Management**: Redis-powered job queuing faster than a speeding bullet
- **🏥 Health Monitoring**: Comprehensive health checks that would make Dr. Hamilton proud
- **🔧 Auto-Deployment**: One-command deployment smoother than Clark Kent's transformation
- **📊 Performance Monitoring**: Real-time insights sharper than Superman's X-ray vision

---

## 🏗️ Architecture Overview - The Fortress of Solitude

Our architecture is designed like Superman's Fortress of Solitude - powerful, secure, and capable of handling any challenge thrown at it. The system uses a multi-layered approach with load balancing, horizontal scaling, and robust data management.

### 🔧 Core Components

| Component | Role | Superpower |
|-----------|------|------------|
| **🔄 Nginx Load Balancer** | Traffic Director | Distributes requests like Superman directing traffic in Metropolis |
| **⚡ n8n Main Instance** | Command Center | Serves the web UI and coordinates all operations |
| **👷 n8n Workers** | The Justice League | Handle background jobs with scalable processing power |
| **🐘 PostgreSQL** | Memory Bank | Stores all workflow data with fortress-level security |
| **🔴 Redis** | Communication Hub | Manages job queues faster than Superman's super-speed |
| **❤️ Health Monitors** | Early Warning System | Detects issues before they become problems |

### 🌟 Key Features

#### 🚀 **Horizontal Scaling**
- **Dynamic Worker Scaling**: Add or remove workers based on demand
- **Load Distribution**: Intelligent job distribution across all workers
- **Resource Optimization**: Efficient CPU and memory utilization
- **Auto-Recovery**: Automatic restart of failed workers

#### 🛡️ **Enterprise Security**
- **Authentication**: Basic auth with configurable credentials
- **Encryption**: AES encryption for sensitive data
- **SSL/TLS**: Secure communication channels
- **Environment Isolation**: Containerized security boundaries

#### ⚡ **Performance Optimization**
- **Queue Management**: Redis-powered job queuing system
- **Connection Pooling**: Optimized database connections
- **Caching**: Intelligent caching for faster response times
- **Health Monitoring**: Real-time performance tracking

#### 🔧 **DevOps Ready**
- **Docker Compose**: One-command deployment
- **Health Checks**: Comprehensive service monitoring
- **Logging**: Centralized log management
- **Backup Support**: Database backup and recovery

---

## 🚀 Quick Start - Suiting Up for Action

### 📋 Prerequisites - Your Hero Training

Before you can join the Justice League of automation, make sure you have these superpowers installed:

| Requirement | Minimum Version | Recommended | Purpose |
|-------------|----------------|-------------|---------|
| **Docker** | 20.10+ | 24.0+ | Container orchestration |
| **Docker Compose** | 2.0+ | 2.20+ | Multi-container management |
| **System RAM** | 4GB | 8GB+ | Smooth operation |
| **CPU Cores** | 2 | 4+ | Parallel processing |
| **Disk Space** | 10GB | 20GB+ | Data storage |

### 🎯 Mission 1: Clone the Fortress

```bash
git clone https://github.com/2Ways-Technology/n8n-superman-ai.git
cd n8n-superman-ai
```

### 🔧 Mission 2: Configure Your Powers

1. **Create your environment configuration:**
```bash
cp .env_sample .env
```

2. **Edit the `.env` file with your super-secret credentials:**
```bash
nano .env  # or use your favorite editor
```

**🔑 Critical Configuration Variables:**

```bash
# Database Configuration (Your Fortress Database)
GCP_CLOUDSQL_HOST=your-database-host
POSTGRES_PASSWORD="your-super-secret-password"

# Redis Configuration (Your Communication Hub)
REDIS_CLOUD_HOST=your-redis-host
REDIS_CLOUD_PASSWORD=your-redis-password

# n8n Security (Your Secret Identity)
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-admin-password
N8N_ENCRYPTION_KEY=your-32-character-encryption-key

# Worker Configuration (Your Justice League)
EXECUTIONS_MODE=queue
N8N_WORKERS_ENABLED=true
N8N_WORKER_CONCURRENCY=10
```

> **🦸‍♂️ Pro Tip**: Generate a strong encryption key using:
> ```bash
> openssl rand -base64 32
> ```

### ⚡ Mission 3: Deploy Your Fortress

Launch your automation fortress with a single command:

```bash
./scripts/deploy-scaled.sh
```

This script will:
- ✅ Check all prerequisites
- 🐳 Pull the latest Docker images
- 🚀 Start the main n8n instance
- 👷 Initialize worker processes
- 🔄 Configure the load balancer
- ❤️ Run health checks

### 🎉 Mission 4: Verify Your Powers

Ensure everything is working perfectly:

```bash
./scripts/verify-installation.sh
```

This verification script checks:
- ✅ Docker and Docker Compose installation
- ✅ Environment configuration
- ✅ Service health and accessibility
- ✅ Worker scaling capabilities
- ✅ Load balancer functionality

---

## 🎮 Usage Examples - Powers in Action

### 🚀 Basic Operations

#### Access Your Fortress
- **Main Interface**: http://localhost:5678
- **Load Balanced**: http://localhost:80
- **Health Check**: http://localhost:80/nginx-health

#### Login Credentials
Use the credentials you set in your `.env` file:
- **Username**: Value of `N8N_BASIC_AUTH_USER`
- **Password**: Value of `N8N_BASIC_AUTH_PASSWORD`

### ⚡ Scaling Your Justice League

#### Scale Workers Up
```bash
# Add more heroes to your team
./scripts/scale-n8n.sh scale 5
```

#### Check Current Status
```bash
# See how many heroes are active
./scripts/scale-n8n.sh status
```

#### Scale Workers Down
```bash
# Reduce team size during quiet periods
./scripts/scale-n8n.sh scale 2
```

#### Stop All Workers
```bash
# Emergency shutdown
./scripts/scale-n8n.sh stop
```

### 📊 Monitoring Your Fortress

#### Real-time Performance Monitoring
```bash
# Monitor like Superman's super-hearing
./scripts/monitor-performance.sh monitor
```

#### Health Check All Services
```bash
# Comprehensive health scan
./scripts/health-check.sh
```

#### View Service Logs
```bash
# See what's happening in your fortress
docker compose logs -f n8n
docker compose logs -f n8n-worker
docker compose logs -f nginx
```

### 🛠️ Advanced Operations

#### Restart Specific Services
```bash
# Restart the main instance
docker compose restart n8n

# Restart all workers
docker compose restart n8n-worker

# Restart load balancer
docker compose restart nginx
```

#### Update to Latest Version
```bash
# Pull latest images and restart
docker compose pull
docker compose up -d
```

#### Backup Your Data
```bash
# Backup n8n data volume
docker run --rm -v n8n-superman-ai_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz -C /data .
```

## 📁 Project Structure - Fortress Layout

```
n8n-superman-ai/
├── 📄 README.md                    # This heroic documentation
├── 📜 LICENSE                      # GPL-2.0 License (Open Source Power!)
├── 🐳 docker-compose.yaml          # The Fortress Blueprint
├── ⚙️ .env_sample                  # Configuration Template
├── 🚫 .gitignore                   # Secret Files Protection
├── 📋 DOCUMENTATION_SUMMARY.md     # Project Enhancement Summary
├── 📁 scripts/                     # Hero Management Tools
│   ├── 🚀 deploy-scaled.sh         # Fortress Deployment Script
│   ├── ❤️ health-check.sh          # Health Monitoring System
│   ├── 📊 monitor-performance.sh   # Performance Tracking Tool
│   ├── ⚡ scale-n8n.sh             # Worker Scaling Manager
│   └── ✅ verify-installation.sh   # Installation Verification
└── 📁 nginx/                       # Load Balancer Configuration
    └── 📁 load-balancer/
        └── ⚙️ n8n-load-balancer.conf # Nginx Configuration
```

### 🔍 File Descriptions

#### 🐳 **docker-compose.yaml** - The Fortress Blueprint
The heart of your automation fortress, defining:
- **n8n Main Service**: The command center (port 5678)
- **n8n Workers**: Scalable background job processors
- **Nginx Load Balancer**: Traffic distribution (port 80)
- **Health Checks**: Automated service monitoring
- **Resource Limits**: Memory and CPU constraints

#### ⚙️ **.env Configuration** - Your Secret Identity
Critical environment variables that power your fortress:

<details>
<summary>🔑 <strong>Database Configuration</strong></summary>

```bash
# PostgreSQL (Your Fortress Database)
GCP_CLOUDSQL_HOST=your-database-host
GCP_CLOUDSQL_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD="your-secure-password"
POSTGRES_DB=postgres
```
</details>

<details>
<summary>🔴 <strong>Redis Configuration</strong></summary>

```bash
# Redis Cloud (Communication Hub)
REDIS_CLOUD_HOST=your-redis-endpoint
REDIS_CLOUD_PORT=11048
REDIS_CLOUD_USERNAME=default
REDIS_CLOUD_PASSWORD=your-redis-password
```
</details>

<details>
<summary>🦸‍♂️ <strong>n8n Security Settings</strong></summary>

```bash
# Authentication & Security
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-admin-password
N8N_ENCRYPTION_KEY=your-32-character-key
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
```
</details>

<details>
<summary>👷 <strong>Worker Configuration</strong></summary>

```bash
# Queue & Worker Settings
EXECUTIONS_MODE=queue
N8N_WORKERS_ENABLED=true
N8N_WORKER_CONCURRENCY=10
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
```
</details>

#### 🛠️ **Management Scripts** - Your Hero Tools

| Script | Purpose | Superpower |
|--------|---------|------------|
| `deploy-scaled.sh` | 🚀 Deploy the entire fortress | One-command deployment |
| `scale-n8n.sh` | ⚡ Manage worker scaling | Dynamic team management |
| `health-check.sh` | ❤️ Monitor service health | Early problem detection |
| `monitor-performance.sh` | 📊 Track performance metrics | Real-time insights |
| `verify-installation.sh` | ✅ Verify setup completion | Installation validation |

#### 🔄 **Nginx Load Balancer** - Traffic Control
- **Upstream Configuration**: Routes traffic to n8n instances
- **Health Checks**: Monitors backend service availability
- **WebSocket Support**: Enables real-time communication
- **Connection Pooling**: Optimizes connection management
- **Retry Logic**: Handles failed requests gracefully

---

## 🔧 Configuration Guide - Customizing Your Powers

### 🌍 Environment Variables Reference

#### 🔒 **Security Configuration**
```bash
# Basic Authentication
N8N_BASIC_AUTH_USER=admin                    # Admin username
N8N_BASIC_AUTH_PASSWORD=secure_password      # Admin password

# Encryption & Security
N8N_ENCRYPTION_KEY=32-character-random-key   # Data encryption key
N8N_SECURE_COOKIE=false                      # HTTPS cookie security
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true  # File permission enforcement
```

#### 🌐 **Network Configuration**
```bash
# Host & Protocol Settings
N8N_HOST=localhost                           # Host binding
N8N_PROTOCOL=http                            # Protocol (http/https)
N8N_EDITOR_BASE_URL=http://localhost:5678    # Editor URL
WEBHOOK_URL=http://localhost:5678/           # Webhook base URL
```

#### ⚡ **Performance Tuning**
```bash
# Worker Configuration
N8N_WORKER_CONCURRENCY=10                   # Jobs per worker
N8N_WORKERS_ENABLED=true                    # Enable workers
EXECUTIONS_MODE=queue                       # Queue mode for scaling

# Database Optimization
DB_POSTGRESDB_POOL_SIZE=2                   # Connection pool size
DB_POSTGRESDB_POOL_SIZE_MAX=10              # Max connections
```

#### 📧 **Email Configuration**
```bash
# SMTP Settings
N8N_EMAIL_MODE=smtp                         # Email mode
N8N_SMTP_HOST=smtp.gmail.com               # SMTP server
N8N_SMTP_PORT=587                          # SMTP port
N8N_SMTP_USER=your-email@gmail.com         # SMTP username
N8N_SMTP_PASS=your-app-password            # SMTP password
```

## 🛠️ Troubleshooting - Defeating the Villains

Even Superman faces challenges! Here's how to overcome common issues in your automation fortress.

### 🦹‍♂️ Common Villains (Issues) and How to Defeat Them

#### 🔥 **Lex Luthor's Database Connection Issues**

**Symptoms**: n8n can't connect to PostgreSQL
```bash
Error: Connection to database failed
```

**Hero Solution**:
1. **Check your database credentials**:
```bash
# Verify .env file settings
grep -E "POSTGRES|GCP_CLOUDSQL" .env
```

2. **Test database connectivity**:
```bash
# Test connection from container
docker compose exec n8n sh -c 'nc -zv $DB_POSTGRESDB_HOST $DB_POSTGRESDB_PORT'
```

3. **Check firewall rules**:
   - Ensure your GCP Cloud SQL allows connections from your IP
   - Verify SSL mode settings match your database configuration

#### 🌪️ **Doomsday's Redis Connection Problems**

**Symptoms**: Workers can't connect to Redis queue
```bash
Error: Redis connection failed
```

**Hero Solution**:
1. **Verify Redis credentials**:
```bash
# Check Redis configuration
grep -E "REDIS_CLOUD" .env
```

2. **Test Redis connectivity**:
```bash
# Test Redis connection
docker compose exec n8n sh -c 'nc -zv $REDIS_CLOUD_HOST $REDIS_CLOUD_PORT'
```

3. **Check Redis Cloud settings**:
   - Verify username/password combination
   - Ensure Redis Cloud instance is running
   - Check connection limits

#### 🤖 **Brainiac's Worker Scaling Issues**

**Symptoms**: Workers not scaling or responding
```bash
Error: Workers not processing jobs
```

**Hero Solution**:
1. **Verify queue mode is enabled**:
```bash
# Check execution mode
grep "EXECUTIONS_MODE" .env
# Should be: EXECUTIONS_MODE=queue
```

2. **Check worker configuration**:
```bash
# Verify worker settings
grep -E "N8N_WORKER|OFFLOAD" .env
```

3. **Restart worker services**:
```bash
# Restart all workers
docker compose restart n8n-worker
```

#### 🌊 **General Zod's Port Conflicts**

**Symptoms**: Services can't start due to port conflicts
```bash
Error: Port already in use
```

**Hero Solution**:
1. **Check what's using the ports**:
```bash
# Check port 5678 (n8n)
lsof -i :5678

# Check port 80 (nginx)
lsof -i :80
```

2. **Stop conflicting services**:
```bash
# Stop Apache/other web servers
sudo systemctl stop apache2
sudo systemctl stop nginx
```

3. **Change ports if needed** (edit docker-compose.yaml):
```yaml
ports:
  - "8080:5678"  # Change external port
```

### 🔍 **Diagnostic Commands - Your X-Ray Vision**

#### 📊 **Service Status Check**
```bash
# Check all service status
docker compose ps

# Check specific service health
docker compose ps n8n
docker compose ps nginx
```

#### 📝 **Log Analysis**
```bash
# View all logs
docker compose logs

# Follow specific service logs
docker compose logs -f n8n
docker compose logs -f n8n-worker
docker compose logs -f nginx

# View last 50 lines
docker compose logs --tail=50 n8n
```

#### 🔧 **Resource Monitoring**
```bash
# Check container resource usage
docker stats

# Check system resources
htop
df -h
free -h
```

#### 🌐 **Network Connectivity**
```bash
# Test internal connectivity
docker compose exec n8n ping nginx
docker compose exec nginx ping n8n

# Test external connectivity
curl -I http://localhost:5678
curl -I http://localhost:80
```

### 🆘 **Emergency Procedures**

#### 🚨 **Complete System Reset**
```bash
# Nuclear option - reset everything
docker compose down -v
docker system prune -f
cp .env_sample .env
# Edit .env with your settings
./scripts/deploy-scaled.sh
```

#### 🔄 **Service Recovery**
```bash
# Restart specific services
docker compose restart n8n
docker compose restart nginx

# Recreate problematic containers
docker compose up -d --force-recreate n8n
```

#### 💾 **Data Recovery**
```bash
# Restore from backup
docker run --rm -v n8n-superman-ai_n8n_data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n-backup-YYYYMMDD.tar.gz -C /data
```

### 📞 **Getting Help - Calling the Justice League**

If you're still facing issues after trying these solutions:

1. **Check the logs first**: `docker compose logs`
2. **Run the verification script**: `./scripts/verify-installation.sh`
3. **Check system resources**: Ensure adequate RAM and disk space
4. **Review configuration**: Double-check your `.env` file settings

## 🤝 Contributing - Join the Justice League

We welcome heroes of all skill levels to contribute to the n8n Superman AI project! Whether you're a coding superhero or just starting your journey, there's a place for you in our Justice League.

### 🦸‍♂️ **How to Become a Hero**

#### 🌟 **For New Heroes (Beginners)**
- 📝 **Documentation**: Help improve our guides and tutorials
- 🐛 **Bug Reports**: Report issues you encounter with detailed information
- 💡 **Feature Suggestions**: Share ideas for new superpowers
- 🧪 **Testing**: Help test new features and configurations

#### ⚡ **For Experienced Heroes (Intermediate)**
- 🔧 **Bug Fixes**: Solve existing issues and improve stability
- 📊 **Monitoring**: Enhance health checks and performance monitoring
- 🐳 **Docker Optimization**: Improve container configurations
- 📚 **Examples**: Create new usage examples and tutorials

#### 🚀 **For Super Heroes (Advanced)**
- 🏗️ **Architecture**: Design new scaling strategies
- 🔒 **Security**: Implement advanced security features
- 🌐 **Networking**: Optimize load balancing and routing
- 🤖 **Automation**: Create new management scripts and tools

### 📋 **Contribution Process**

1. **🍴 Fork the Repository**
```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/n8n-superman-ai.git
cd n8n-superman-ai
```

2. **🌿 Create a Feature Branch**
```bash
# Create a descriptive branch name
git checkout -b feature/add-super-scaling
git checkout -b fix/database-connection-issue
git checkout -b docs/improve-installation-guide
```

3. **💻 Make Your Changes**
- Follow existing code style and conventions
- Add comments explaining complex logic
- Update documentation if needed
- Test your changes thoroughly

4. **🧪 Test Your Changes**
```bash
# Run the verification script
./scripts/verify-installation.sh

# Test scaling functionality
./scripts/scale-n8n.sh scale 3
./scripts/scale-n8n.sh status

# Check health monitoring
./scripts/health-check.sh
```

5. **📝 Commit Your Changes**
```bash
# Use descriptive commit messages
git add .
git commit -m "feat: add auto-scaling based on CPU usage"
git commit -m "fix: resolve Redis connection timeout issue"
git commit -m "docs: improve troubleshooting section"
```

6. **🚀 Submit a Pull Request**
- Push your branch to your fork
- Create a pull request with a clear description
- Reference any related issues
- Wait for review and feedback

### 🎯 **Contribution Guidelines**

#### ✅ **Do's**
- ✅ Write clear, descriptive commit messages
- ✅ Include tests for new features
- ✅ Update documentation for changes
- ✅ Follow the existing code style
- ✅ Be respectful and constructive in discussions

#### ❌ **Don'ts**
- ❌ Submit untested changes
- ❌ Break existing functionality
- ❌ Include sensitive information (passwords, keys)
- ❌ Make unrelated changes in a single PR
- ❌ Ignore feedback from maintainers

### 🏆 **Recognition**

Contributors will be recognized in our Hall of Fame! We appreciate:
- 🥇 **Code Contributors**: Direct code improvements
- 🥈 **Documentation Heroes**: Documentation improvements
- 🥉 **Community Champions**: Helping others and reporting issues

---

## 📄 License - The Hero's Code

This project is licensed under the **GNU General Public License v2.0** - see the [LICENSE](LICENSE) file for details.

### 🦸‍♂️ **What This Means**

- ✅ **Freedom to Use**: Use this software for any purpose
- ✅ **Freedom to Study**: Examine and understand how it works
- ✅ **Freedom to Share**: Distribute copies to help others
- ✅ **Freedom to Improve**: Modify and distribute improvements

### 🛡️ **Your Responsibilities**

- 📝 **Share Alike**: Distribute modifications under the same license
- 🏷️ **Attribution**: Keep copyright notices intact
- 📋 **Source Code**: Provide source code with distributions
- 🔓 **No Additional Restrictions**: Don't add extra limitations

---

## 📞 Contact & Support - Reach Out to the Heroes

### 🦸‍♂️ **Project Maintainers**

**2Ways Technology Team**
- 🌐 **Website**: [2ways.tech](https://2ways.tech)
- 📧 **Email**: support@2ways.tech
- 🐙 **GitHub**: [@2Ways-Technology](https://github.com/2Ways-Technology)

### 💬 **Community & Support**

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/2Ways-Technology/n8n-superman-ai/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/2Ways-Technology/n8n-superman-ai/discussions)
- 📚 **Documentation**: This README and inline comments
- 🤝 **Contributions**: Pull requests welcome!

### 🆘 **Getting Help**

1. **📖 Check the Documentation**: Start with this README
2. **🔍 Search Existing Issues**: Someone might have faced the same problem
3. **🧪 Run Diagnostics**: Use our verification and health check scripts
4. **📝 Create an Issue**: Provide detailed information about your problem

### 🌟 **Show Your Support**

If this project helps you build amazing automations:
- ⭐ **Star the Repository**: Show your appreciation
- 🍴 **Fork and Contribute**: Help make it even better
- 📢 **Share with Others**: Spread the automation superpowers
- 💝 **Sponsor the Project**: Support ongoing development

---

## 🎉 Final Words - Your Hero's Journey Begins

Congratulations! You now have the power to deploy and manage a production-ready, horizontally scalable n8n automation platform. With great automation comes great responsibility - use these powers wisely to make the digital world a better place.

### 🚀 **What's Next?**

1. **🏗️ Build Amazing Workflows**: Create powerful automations
2. **📈 Scale with Confidence**: Handle enterprise workloads
3. **🤝 Join the Community**: Share your experiences and help others
4. **🔧 Contribute Back**: Help improve the platform for everyone

### 🦸‍♂️ **Remember**

*"The measure of a hero is not the size of their strength, but the strength of their automation workflows."*

---

<div align="center">

**🦸‍♂️ Made with ❤️ by the 2Ways Technology Team**

*Empowering automation heroes worldwide*

[![GitHub](https://img.shields.io/badge/GitHub-2Ways--Technology-black?style=for-the-badge&logo=github)](https://github.com/2Ways-Technology)
[![Website](https://img.shields.io/badge/Website-2ways.tech-blue?style=for-the-badge&logo=web)](https://2ways.tech)

**⚡ "With great automation comes great responsibility!" ⚡**

</div>
