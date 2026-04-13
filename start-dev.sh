#!/bin/bash

# =============================================================================
# GAAP Development Environment Management Script
# For Linux/macOS
# =============================================================================

set -e

# Configuration
COMPOSE_FILE="docker-middleware-compose.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Auto-detect Docker Compose command (v2 plugin vs v1 standalone)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' found."
    echo "Please install Docker with Compose plugin or standalone docker-compose."
    exit 1
fi

# Service groups (middleware only - API and Web run locally)
MIDDLEWARE_SERVICES="postgres redis rabbitmq caddy"
API_SERVICES="gaap-api"
WEB_SERVICES="gaap-web"
ALL_SERVICES="$MIDDLEWARE_SERVICES"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# =============================================================================
# Local Development Functions (Native Linux/macOS)
# =============================================================================

start_middleware() {
    print_header "Starting middleware services"
    print_info "Services: $MIDDLEWARE_SERVICES"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d $MIDDLEWARE_SERVICES
    print_success "Middleware services started successfully!"
}

stop_middleware() {
    print_header "Stopping middleware services"
    print_info "Services: $MIDDLEWARE_SERVICES"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop $MIDDLEWARE_SERVICES
    print_success "Middleware services stopped successfully!"
}

start_local_api() {
    print_header "Starting GAAP API (Local)"
    cd "$SCRIPT_DIR/gaap-api"
    if [ ! -f "go.mod" ]; then
        print_error "go.mod not found. Please ensure you're in the correct directory."
        cd "$SCRIPT_DIR"
        return 1
    fi
    
    # Sync .env file
    print_info "Syncing .env file to API directory..."
    cp ../.env .env
    # Replace hosts for local access (compatible with both GNU and BSD sed)
    sed -i.bak -e 's/POSTGRES_HOST=postgres/POSTGRES_HOST=127.0.0.1/g' \
               -e 's/REDIS_HOST=redis/REDIS_HOST=127.0.0.1/g' \
               -e 's/RABBITMQ_HOST=rabbitmq/RABBITMQ_HOST=127.0.0.1/g' .env
    rm -f .env.bak
    
    print_info "Installing Go dependencies..."
    go mod download
    print_info "Starting API server with hot-reload..."
    air &
    cd "$SCRIPT_DIR"
    print_success "GAAP API started on http://localhost:8000"
    print_info "Press Ctrl+C to stop"
}

stop_local_api() {
    print_header "Stopping GAAP API (Local)"
    pkill -f "air" 2>/dev/null || print_info "API process not found or already stopped"
    print_success "GAAP API stopped successfully!"
}

start_local_web() {
    print_header "Starting GAAP Web (Local)"
    cd "$SCRIPT_DIR/gaap-web"
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please ensure you're in the correct directory."
        cd "$SCRIPT_DIR"
        return 1
    fi
    
    # Sync .env file
    print_info "Syncing .env file to Web directory as .env.local..."
    cp ../.env .env.local
    # Replace hosts for local access (compatible with both GNU and BSD sed)
    sed -i.bak -e 's/POSTGRES_HOST=postgres/POSTGRES_HOST=127.0.0.1/g' \
               -e 's/REDIS_HOST=redis/REDIS_HOST=127.0.0.1/g' \
               -e 's/RABBITMQ_HOST=rabbitmq/RABBITMQ_HOST=127.0.0.1/g' \
               -e 's/^ALE_BOOTSTRAP_KEY=/NEXT_PUBLIC_ALE_BOOTSTRAP_KEY=/g' \
               -e 's/^TURNSTILE_SITE_KEY=/NEXT_PUBLIC_TURNSTILE_SITE_KEY=/g' .env.local
    rm -f .env.local.bak
    
    if [ ! -d "node_modules" ]; then
        print_info "Installing Node.js dependencies..."
        npm install
    fi
    print_info "Starting Next.js development server..."
    npm run dev &
    cd "$SCRIPT_DIR"
    print_success "GAAP Web started on http://localhost:3000"
    print_info "Press Ctrl+C to stop"
}

stop_local_web() {
    print_header "Stopping GAAP Web (Local)"
    pkill -f "next dev" 2>/dev/null || print_info "Web process not found or already stopped"
    print_success "GAAP Web stopped successfully!"
}

# Get services based on target
get_services() {
    local target=$1
    case $target in
        middleware)
            echo "$MIDDLEWARE_SERVICES"
            ;;
        api)
            echo "$API_SERVICES"
            ;;
        web)
            echo "$WEB_SERVICES"
            ;;
        all)
            echo "$ALL_SERVICES"
            ;;
        *)
            print_error "Unknown target: $target"
            print_info "Valid targets: middleware, api, web, all"
            exit 1
            ;;
    esac
}

# =============================================================================
# Core Functions
# =============================================================================

# Start services
start_services() {
    local target=${1:-all}
    
    # Handle local services (api/web) differently from middleware
    if [ "$target" = "api" ]; then
        start_local_api
        return
    fi
    if [ "$target" = "web" ]; then
        start_local_web
        return
    fi
    if [ "$target" = "all" ]; then
        start_middleware
        start_local_api
        start_local_web
        return
    fi
    
    # Start middleware only
    local services=$(get_services "$target")
    print_header "Starting $target services"
    print_info "Services: $services"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d $services
    print_success "$target services started successfully!"
    echo ""
    print_info "To view logs, run: ./start-dev.sh logs $target"
}

# Stop services
stop_services() {
    local target=${1:-all}
    
    # Handle local services (api/web) differently from middleware
    if [ "$target" = "api" ]; then
        stop_local_api
        return
    fi
    if [ "$target" = "web" ]; then
        stop_local_web
        return
    fi
    if [ "$target" = "all" ]; then
        stop_local_api
        stop_local_web
        stop_middleware
        return
    fi
    
    # Stop middleware only
    local services=$(get_services "$target")
    print_header "Stopping $target services"
    print_info "Services: $services"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop $services
    print_success "$target services stopped successfully!"
}

# Restart services
restart_services() {
    local target=${1:-all}
    
    # Handle local services (api/web) differently from middleware
    if [ "$target" = "api" ]; then
        stop_local_api
        start_local_api
        return
    fi
    if [ "$target" = "web" ]; then
        stop_local_web
        start_local_web
        return
    fi
    if [ "$target" = "all" ]; then
        stop_local_api
        stop_local_web
        stop_middleware
        start_middleware
        start_local_api
        start_local_web
        return
    fi
    
    # Restart middleware only
    stop_services "$target"
    start_services "$target"
}

# Show service logs (supports multiple targets)
show_logs() {
    local targets="${@:-all}"
    local all_services=""
    
    # Collect services from all specified targets
    for target in $targets; do
        local services=$(get_services "$target")
        all_services="$all_services $services"
    done
    
    # Remove leading space and deduplicate
    all_services=$(echo $all_services | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    print_header "Showing logs for: $targets"
    print_info "Services: $all_services"
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs -f $all_services
}

# Show service status
show_status() {
    print_header "Service Status"
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps
}

# Clean up - remove containers, volumes, and build cache
clean() {
    local target=${1:-all}
    
    print_header "Cleaning up $target"
    
    if [ "$target" = "all" ]; then
        print_warning "This will remove all containers, anonymous volumes, and build cache."
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "Cleanup cancelled."
            exit 0
        fi
        
        print_info "Stopping all services..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down -v --remove-orphans
        
        print_info "Pruning build cache..."
        docker builder prune -f 2>/dev/null || true
        
        print_success "Full cleanup completed!"
    else
        local services=$(get_services "$target")
        print_info "Stopping and removing $target services..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop $services
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" rm -f $services
        print_success "$target cleanup completed!"
    fi
}

# Install/reinstall dependencies
install_deps() {
    local target=${1:-all}
    
    print_header "Installing dependencies for $target"
    
    if [ "$target" = "middleware" ]; then
        print_info "Middleware services don't require dependency installation."
        return
    fi
    
    if [ "$target" = "api" ] || [ "$target" = "all" ]; then
        print_info "Installing Go dependencies..."
        cd "$SCRIPT_DIR/gaap-api"
        go mod download
        cd "$SCRIPT_DIR"
        print_success "Go dependencies installed!"
    fi
    
    if [ "$target" = "web" ] || [ "$target" = "all" ]; then
        print_info "Installing Node.js dependencies..."
        cd "$SCRIPT_DIR/gaap-web"
        npm install
        cd "$SCRIPT_DIR"
        print_success "Node.js dependencies installed!"
    fi
    
    print_success "Dependencies installation completed!"
}

# Rebuild services (for refreshing dependencies in containers)
rebuild() {
    local target=${1:-all}
    
    print_header "Rebuilding $target services"
    
    # Handle local services (api/web) differently from middleware
    if [ "$target" = "api" ]; then
        print_info "Rebuilding API server..."
        cd "$SCRIPT_DIR/gaap-api"
        go clean -cache
        go mod download
        cd "$SCRIPT_DIR"
        print_success "API server rebuilt!"
        return
    fi
    
    if [ "$target" = "web" ]; then
        print_info "Rebuilding Web application..."
        cd "$SCRIPT_DIR/gaap-web"
        rm -rf node_modules/.next
        npm install
        cd "$SCRIPT_DIR"
        print_success "Web application rebuilt!"
        return
    fi
    
    if [ "$target" = "all" ]; then
        print_info "Rebuilding API server..."
        cd "$SCRIPT_DIR/gaap-api"
        go clean -cache
        go mod download
        cd "$SCRIPT_DIR"
        print_success "API server rebuilt!"
        
        print_info "Rebuilding Web application..."
        cd "$SCRIPT_DIR/gaap-web"
        rm -rf node_modules/.next
        npm install
        cd "$SCRIPT_DIR"
        print_success "Web application rebuilt!"
        
        print_info "Rebuilding middleware..."
        stop_middleware
        start_middleware
        return
    fi
    
    # Rebuild middleware only
    local services=$(get_services "$target")
    print_info "Services: $services"
    stop_middleware
    start_middleware
    
    print_success "$target services rebuilt and started!"
    print_info "Hot-reload is active. Changes to source files will be reflected automatically."
}

# Execute command in container
exec_cmd() {
    local target=$1
    shift
    local cmd="$@"
    
    if [ -z "$cmd" ]; then
        print_error "No command specified."
        exit 1
    fi
    
    case $target in
        api)
            cd "$SCRIPT_DIR/gaap-api"
            $cmd
            cd "$SCRIPT_DIR"
            ;;
        web)
            cd "$SCRIPT_DIR/gaap-web"
            $cmd
            cd "$SCRIPT_DIR"
            ;;
        *)
            print_error "exec only supports 'api' or 'web' targets"
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    echo -e "${BLUE}GAAP Development Environment Management Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "    ./start-dev.sh <command> [target]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "    start [target]      Start services (default: all)"
    echo "    stop [target]       Stop services (default: all)"
    echo "    restart [target]    Restart services (default: all)"
    echo "    logs [targets...]   Show service logs, supports multiple (default: all)"
    echo "    status              Show service status"
    echo "    clean [target]      Clean up containers and volumes (default: all)"
    echo "    install [target]    Install/reinstall dependencies (default: all)"
    echo "    rebuild [target]    Rebuild and restart services (default: all)"
    echo "    exec <target> <cmd> Execute command in local directory (api/web only)"
    echo "    help                Show this help message"
    echo ""
    echo -e "${YELLOW}Targets:${NC}"
    echo "    middleware          PostgreSQL, Redis, RabbitMQ (Docker containers)"
    echo "    api                 GAAP API (GoFrame backend) - Runs locally with hot-reload"
    echo "    web                 GAAP Web (Next.js frontend) - Runs locally with HMR"
    echo "    all                 All services (default)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "    ./start-dev.sh start                    # Start all services"
    echo "    ./start-dev.sh start middleware         # Start only middleware"
    echo "    ./start-dev.sh restart web              # Restart web service"
    echo "    ./start-dev.sh logs middleware          # View middleware logs"
    echo "    ./start-dev.sh clean middleware         # Clean middleware containers"
    echo "    ./start-dev.sh install web              # Reinstall npm dependencies"
    echo "    ./start-dev.sh rebuild api              # Rebuild API service"
    echo "    ./start-dev.sh exec api go test ./...   # Run tests in API directory"
    echo "    ./start-dev.sh exec web npm run lint    # Run linting in web directory"
    echo ""
    echo -e "${YELLOW}Hot-Reload:${NC}"
    echo "    - API: Uses 'air' for automatic Go rebuilds (http://localhost:8000)"
    echo "    - Web: Uses Next.js built-in HMR (http://localhost:3000)"
    echo ""
    echo -e "${YELLOW}Notes:${NC}"
    echo "    - API and Web services run locally for optimal HMR performance"
    echo "    - Middleware (Postgres, Redis, RabbitMQ) run in Docker containers"
    echo "    - Use 'install' or 'rebuild' to refresh dependencies"
    echo "    - Use 'clean' to remove middleware containers and volumes"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Parse command
command=${1:-help}
target=${2:-all}

case $command in
    start)
        start_services "$target"
        ;;
    stop)
        stop_services "$target"
        ;;
    restart)
        restart_services "$target"
        ;;
    logs)
        shift  # Remove 'logs' from arguments
        show_logs "$@"
        ;;
    status)
        show_status
        ;;
    clean)
        clean "$target"
        ;;
    install)
        install_deps "$target"
        ;;
    rebuild)
        rebuild "$target"
        ;;
    exec)
        shift 2 2>/dev/null || shift 1
        exec_cmd "$target" "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $command"
        show_help
        exit 1
        ;;
esac
