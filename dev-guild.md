# 📘 Local Development Guide

## Overview

GAAP uses a **hybrid development model** for optimal performance:

- **API (Go)**: Runs locally with `air` hot-reload
- **Web (Next.js)**: Runs locally with native HMR
- **Middleware (Postgres, Redis, RabbitMQ, Caddy)**: Runs in Docker containers

This architecture provides the best HMR experience on Windows/macOS while keeping infrastructure isolated. Caddy provides HTTPS automatically for local development.

## Prerequisites

### Required Software

- **Go 1.24+**: [Download](https://go.dev/dl/)
- **Node.js 22+**: [Download](https://nodejs.org/)
- **Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop/)
- **Git**: [Download](https://git-scm.com/)

### Install Development Tools

```shell
# Install Air for Go hot-reload
go install github.com/air-verse/air@v1.61.7

# Install Delve for Go debugging (optional)
go install github.com/go-delve/delve/cmd/dlv@latest
```

## Environment Variables

### Shared Configuration

The root `.env` file is shared across all services via symlinks:

```
gaap/
├── .env                    # Single source of truth
├── gaap-api/
│   └── .env -> ../.env     # Symlink (auto-created)
└── gaap-web/
    └── .env.local -> ../.env  # Symlink (auto-created)
```

### Auto-Creation

When you run `start-dev.bat start` or `./start-dev.sh start`, symlinks are automatically created.

### Manual Setup

If symlinks fail, create them manually:

**Windows:**
```powershell
cd gaap-api
mklink .env ..\.env

cd gaap-web
mklink .env.local ..\.env
```

**macOS/Linux:**
```shell
cd gaap-api
ln -s ../.env .env

cd gaap-web
ln -s ../.env .env.local
```

### Environment-Specific Overrides

You can create `.env.local` in `gaap-web` to override specific values without modifying the shared `.env`:

```env
# gaap-web/.env.local (overrides)
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

## Configure Local Domain

macOS/Linux:

```shell
sudo nano /etc/hosts

# Add the following line
127.0.0.1 gaap.local
```

Windows:

```shell
# Run Notepad as Administrator
notepad C:\Windows\System32\drivers\etc\hosts

# Add the following line
127.0.0.1 gaap.local
```

## Start Development Environment

### Quick Start (Recommended)

```shell
# 1. Clone project (including submodules)
git clone --recursive https://github.com/gin-melodic/gaap.git
cd gaap

# 2. Configure environment variables
cp .env.example .env
# Modify .env file as needed

# 3. Start all services (middleware + local API/Web)
# Windows
start-dev.bat start

# macOS/Linux
./start-dev.sh start
```

### Manual Start

```shell
# Start only middleware (Docker containers)
# Windows
start-dev.bat start middleware

# macOS/Linux
./start-dev.sh start middleware

# Then manually start API and Web:
# API (in gaap-api directory)
cd gaap-api
air

# Web (in gaap-web directory, new terminal)
cd gaap-web
npm run dev
```

### Using Management Scripts

```shell
# View all commands
start-dev.bat help       # Windows
./start-dev.sh help      # macOS/Linux

# Start/Stop services
start-dev.bat start      # Start all
start-dev.bat stop       # Stop all
start-dev.bat restart    # Restart all

# Start specific services
start-dev.bat start middleware  # Only Docker containers
start-dev.bat start api         # Only API (local)
start-dev.bat start web         # Only Web (local)

# Install dependencies
start-dev.bat install     # Install both API and Web deps
start-dev.bat install api # Install Go dependencies
start-dev.bat install web # Install Node.js dependencies

# View logs (middleware only)
start-dev.bat logs middleware
```

## Access Application

- **Frontend (HTTP)**: http://localhost:3000
- **Frontend (HTTPS)**: https://gaap.local
- **Backend API**: http://localhost:8000
- **API Health**: http://localhost:8000/api/health
- **RabbitMQ Management**: http://localhost:15672
- **Caddy Admin API**: http://localhost:2019

## Golang Debugging Guide

### VSCode Debugging

**Step 1: Configure VSCode**

Create `gaap-api/.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug with Delve",
      "type": "go",
      "request": "launch",
      "mode": "debug",
      "program": "${workspaceFolder}",
      "env": {},
      "args": []
    },
    {
      "name": "Attach to Remote Delve",
      "type": "go",
      "request": "attach",
      "mode": "remote",
      "remotePath": "${workspaceFolder}",
      "port": 40000,
      "host": "localhost",
      "showLog": true,
      "trace": "verbose",
      "logOutput": "rpc"
    }
  ]
}
```

**Step 2: Start Debugging**

1. Open `gaap-api` project in VSCode
2. Set breakpoints in code
3. Press `F5` or click "Run and Debug" → "Debug with Delve"
4. Trigger API requests using browser or Postman
5. Breakpoint triggers in VSCode, view variables, step through, etc.

### GoLand/IntelliJ IDEA

**Step 1: Create Run Configuration**

1. Go to Run → Edit Configurations
2. Add Go Remote configuration:
  - Host: localhost
  - Port: 40000

**Step 2: Start Debugging**

1. Start Delve manually:
   ```shell
   cd gaap-api
   dlv debug --headless --listen=:40000 --api-version=2
   ```
2. Click Debug icon in GoLand

### Hot Reload with Air

Air automatically recompiles Go code when files change:

```shell
# Start with hot reload
cd gaap-api
air

# Configuration: gaap-api/.air.toml
```

## Next.js Development

### Running the Web Application

```shell
cd gaap-web

# Standard development mode
npm run dev

# With polling (for WSL)
npm run dev:docker
```

### Debugging in VSCode

Create `gaap-web/.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Next.js",
      "type": "node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "console": "integratedTerminal"
    }
  ]
}
```

## Database Management

```shell
# Connect to PostgreSQL
docker exec -it gaap-postgres-dev psql -U gaap_user -d gaap

# Import SQL
docker exec -i gaap-postgres-dev psql -U gaap_user -d gaap < schema_ddl.sql

# Backup Database
docker exec gaap-postgres-dev pg_dump -U gaap_user gaap > backup.sql
```

## RabbitMQ Management Interface

Access: http://localhost:15672

- Username: `gaap_mq`
- Password: `RABBITMQ_PASSWORD` in `.env`

## Trust Self-Signed Certificates

Browser will warn about untrusted certificate on first access, this is normal.

### Method 1: Browser Direct Trust (Temporary)

- Chrome/Edge: Click "Advanced" → "Proceed"
- Firefox: Click "Advanced" → "Accept the Risk and Continue"

### Method 2: Import Caddy Root Certificate (Permanent)

```shell
# Export Caddy root certificate
docker exec gaap-caddy-dev cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt

# macOS: Add to Keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain caddy-root.crt

# Linux (Ubuntu/Debian)
sudo cp caddy-root.crt /usr/local/share/ca-certificates/caddy-root.crt
sudo update-ca-certificates

# Windows: Double click caddy-root.crt → Install Certificate → Trusted Root Certification Authorities
```

## Verify Configuration

```shell
# Test API connection
curl -k https://gaap.local/api/health

# View Caddy configuration
curl http://localhost:2019/config/ | jq

# Test frontend-backend communication (no CORS issues)
curl -k https://gaap.local/api/v1/users

# Check certificate
openssl s_client -connect gaap.local:443 -servername gaap.local
```

## Troubleshooting Common Issues

### Issue 1: Delve Connection Failed

```shell
# Check if port is open
netstat -an | grep 40000

# Check container permissions
docker inspect gaap-api-dev | grep -A 5 CapAdd

# Ensure SYS_PTRACE permission
```

### Issue 2: Hot Reload Not Working

```shell
# Check Volume mounts
docker-compose -f docker-compose.dev.yml config | grep volumes -A 5

# Manually trigger recompilation
docker exec -it gaap-api-dev air
```

### Issue 3: Go Module Download Slow

```shell
# Use Go Proxy (China Region)
docker exec -it gaap-api-dev sh
go env -w GOPROXY=https://goproxy.cn,direct
```

## Database Management

```shell
# Connect to PostgreSQL
docker exec -it gaap-postgres-dev psql -U gaap_user -d gaap

# Import SQL
docker exec -i gaap-postgres-dev psql -U gaap_user -d gaap < schema_ddl.sql

# Backup Database
docker exec gaap-postgres-dev pg_dump -U gaap_user gaap > backup.sql
```

## RabbitMQ Management Interface

Access: http://localhost:15672

- Username: `gaap_mq`
- Password: `RABBITMQ_PASSWORD` in `.env`
