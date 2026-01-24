#!/bin/bash

# =============================================================================
# GAAP Development Environment Management Script
# For Linux/macOS
# =============================================================================

set -e

# Configuration
COMPOSE_FILE="docker-compose.dev.yml"
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

# Service groups
MIDDLEWARE_SERVICES="postgres redis rabbitmq caddy"
API_SERVICES="gaap-api"
WEB_SERVICES="gaap-web"
ALL_SERVICES="$MIDDLEWARE_SERVICES $API_SERVICES $WEB_SERVICES"

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
    local services=$(get_services "$target")
    
    print_header "Starting $target services"
    print_info "Services: $services"
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d $services
    
    print_success "$target services started successfully!"
    
    # Show logs hint
    echo ""
    print_info "To view logs, run: ./start-dev.sh logs $target"
}

# Stop services
stop_services() {
    local target=${1:-all}
    local services=$(get_services "$target")
    
    print_header "Stopping $target services"
    print_info "Services: $services"
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop $services
    
    print_success "$target services stopped successfully!"
}

# Restart services
restart_services() {
    local target=${1:-all}
    local services=$(get_services "$target")
    
    print_header "Restarting $target services"
    
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
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec gaap-api go mod download 2>/dev/null || \
            (cd gaap-api && go mod download)
        print_success "Go dependencies installed!"
    fi
    
    if [ "$target" = "web" ] || [ "$target" = "all" ]; then
        print_info "Installing Node.js dependencies..."
        # Stop web container, remove it to clear anonymous volumes, rebuild and restart
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop gaap-web 2>/dev/null || true
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" rm -f gaap-web 2>/dev/null || true
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" build --no-cache gaap-web
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d gaap-web
        print_success "Node.js dependencies installed!"
    fi
    
    print_success "Dependencies installation completed!"
}

# Rebuild services (for refreshing dependencies in containers)
rebuild() {
    local target=${1:-all}
    local services=$(get_services "$target")
    
    print_header "Rebuilding $target services"
    print_info "Services: $services"
    
    # Stop and remove containers to clear anonymous volumes
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" stop $services
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" rm -f $services
    
    # Rebuild images
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" build $services
    
    # Start services
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d $services
    
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
            $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec gaap-api $cmd
            ;;
        web)
            $DOCKER_COMPOSE -f "$COMPOSE_FILE" exec gaap-web $cmd
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
    echo "    exec <target> <cmd> Execute command in container (api/web only)"
    echo "    help                Show this help message"
    echo ""
    echo -e "${YELLOW}Targets:${NC}"
    echo "    middleware          PostgreSQL, Redis, RabbitMQ, Caddy"
    echo "    api                 GAAP API (GoFrame backend)"
    echo "    web                 GAAP Web (Next.js frontend)"
    echo "    all                 All services (default)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "    ./start-dev.sh start                    # Start all services"
    echo "    ./start-dev.sh start middleware         # Start only middleware"
    echo "    ./start-dev.sh restart web              # Restart web service"
    echo "    ./start-dev.sh logs api web             # View API and web logs together"
    echo "    ./start-dev.sh clean web                # Clean web service"
    echo "    ./start-dev.sh install web              # Reinstall npm dependencies"
    echo "    ./start-dev.sh rebuild api              # Rebuild API service"
    echo "    ./start-dev.sh exec api go test ./...   # Run tests in API container"
    echo "    ./start-dev.sh exec web npm run lint    # Run linting in web container"
    echo ""
    echo -e "${YELLOW}Hot-Reload:${NC}"
    echo "    - API: Uses 'air' for automatic Go rebuilds"
    echo "    - Web: Uses Next.js built-in hot-reload (Turbopack)"
    echo ""
    echo -e "${YELLOW}Notes:${NC}"
    echo "    - Source code is mounted into containers for hot-reload"
    echo "    - Use 'install' or 'rebuild' to refresh dependencies"
    echo "    - Use 'clean' to remove containers and anonymous volumes"
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
