# 📘 Local Development Guide

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

```shell
# 1. Clone project (including submodules)
git clone --recursive https://github.com/gin-melodic/gaap.git
cd gaap

# 2. Configure environment variables
cp .env.example .env
# Modify .env file as needed

# 3. Start all services
docker-compose -f docker-compose.dev.yml up -d

# 4. View logs
docker-compose -f docker-compose.dev.yml logs -f gaap-api
docker-compose -f docker-compose.dev.yml logs -f gaap-web

# 5. Stop services
docker-compose -f docker-compose.dev.yml down

# 6. Full cleanup (including data volumes)
docker-compose -f docker-compose.dev.yml down -v
```

## Golang Debugging Guide

### VSCode Remote Debugging

**Step 1: Enable Delve Debugger**

```shell
# Edit .env file
ENABLE_DELVE=true

# Restart API service
docker-compose -f docker-compose.dev.yml up -d gaap-api
```

**Step 2: Configure VSCode**

Create `gaap-api/.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Connect to Docker Delve",
      "type": "go",
      "request": "attach",
      "mode": "remote",
      "remotePath": "/app",
      "port": 40000,
      "host": "localhost",
      "showLog": true,
      "trace": "verbose",
      "logOutput": "rpc"
    }
  ]
}
```

**Step 3: Start Debugging**

1. Open `gaap-api` project in VSCode
2. Set breakpoints in code
3. Press `F5` or click "Run and Debug" → "Connect to Docker Delve"
4. Trigger API requests using browser or Postman
5. Breakpoint triggers in VSCode, view variables, step through, etc.

**Step 4: Debugging Tips**

```shell
# Enter container to check Delve status
docker exec -it gaap-api-dev sh
ps aux | grep dlv

# View Delve logs
docker logs gaap-api-dev
```

### GoLand/IntelliJ IDEA

**Step 1: Create Run Configuration**

1. Go to Run → Edit Configurations
2. Add Go Remote configuration:
  - Host: localhost
  - Port: 40000
  - On disconnect: Stop remote Delve process

**Step 2: Start Debugging**

1. Ensure ENABLE_DELVE=true
2. Start services: docker-compose -f docker-compose.dev.yml up -d
3. Click Debug icon in GoLand

**Method 3: Hot Reload Debugging without Delve**

If only hot reload is needed (no breakpoints), disable Delve:

```shell
# .env file
ENABLE_DELVE=false

# Restart service
docker-compose -f docker-compose.dev.yml restart gaap-api
```

Use Air for hot reloading, automatically recompiles after code changes.

## Access Application

- Frontend: https://gaap.local
- Backend API: https://gaap.local/api/v1
- RabbitMQ Management Interface: http://localhost:15672
- Caddy Admin API: http://localhost:2019

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
