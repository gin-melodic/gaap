@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: GAAP Development Environment Management Script
:: For Windows
:: =============================================================================

:: Configuration
set "COMPOSE_FILE=docker-compose.dev.yml"
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: Service groups
set "MIDDLEWARE_SERVICES=postgres redis rabbitmq caddy"
set "API_SERVICES=gaap-api"
set "WEB_SERVICES=gaap-web"
set "ALL_SERVICES=%MIDDLEWARE_SERVICES% %API_SERVICES% %WEB_SERVICES%"

:: =============================================================================
:: Main Entry Point
:: =============================================================================

if "%~1"=="" goto :show_help
if "%~1"=="help" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help

:: Check if Docker compose file exists
if not exist "%COMPOSE_FILE%" (
    call :print_error "Docker compose file not found: %COMPOSE_FILE%"
    exit /b 1
)

:: Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not running. Please start Docker first."
    exit /b 1
)

:: Auto-detect Docker Compose command (v2 plugin vs v1 standalone)
docker compose version >nul 2>&1
if not errorlevel 1 (
    set "DOCKER_COMPOSE=docker compose"
) else (
    docker-compose version >nul 2>&1
    if not errorlevel 1 (
        set "DOCKER_COMPOSE=docker-compose"
    ) else (
        call :print_error "Neither 'docker compose' nor 'docker-compose' found."
        call :print_info "Please install Docker with Compose plugin or standalone docker-compose."
        exit /b 1
    )
)

:: Parse command
set "COMMAND=%~1"
set "TARGET=%~2"
if "%TARGET%"=="" set "TARGET=all"

if "%COMMAND%"=="start" goto :start_services
if "%COMMAND%"=="stop" goto :stop_services
if "%COMMAND%"=="restart" goto :restart_services
if "%COMMAND%"=="logs" goto :show_logs
if "%COMMAND%"=="status" goto :show_status
if "%COMMAND%"=="clean" goto :clean
if "%COMMAND%"=="install" goto :install_deps
if "%COMMAND%"=="rebuild" goto :rebuild
if "%COMMAND%"=="exec" goto :exec_cmd

call :print_error "Unknown command: %COMMAND%"
goto :show_help

:: =============================================================================
:: Helper Functions
:: =============================================================================

:print_header
echo.
echo ========================================
echo   %~1
echo ========================================
echo.
goto :eof

:print_success
echo [OK] %~1
goto :eof

:print_warning
echo [WARN] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

:print_info
echo [INFO] %~1
goto :eof

:get_services
set "GET_TARGET=%~1"
if "%GET_TARGET%"=="middleware" (
    set "SERVICES=%MIDDLEWARE_SERVICES%"
) else if "%GET_TARGET%"=="api" (
    set "SERVICES=%API_SERVICES%"
) else if "%GET_TARGET%"=="web" (
    set "SERVICES=%WEB_SERVICES%"
) else if "%GET_TARGET%"=="all" (
    set "SERVICES=%ALL_SERVICES%"
) else (
    call :print_error "Unknown target: %GET_TARGET%"
    call :print_info "Valid targets: middleware, api, web, all"
    exit /b 1
)
goto :eof

:: =============================================================================
:: Core Functions
:: =============================================================================

:start_services
call :print_header "Starting %TARGET% services"
call :get_services %TARGET%
if errorlevel 1 exit /b 1

call :print_info "Services: %SERVICES%"
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" up -d %SERVICES%

call :print_success "%TARGET% services started successfully!"
echo.
call :print_info "To view logs, run: start-dev.bat logs %TARGET%"
goto :eof

:stop_services
call :print_header "Stopping %TARGET% services"
call :get_services %TARGET%
if errorlevel 1 exit /b 1

call :print_info "Services: %SERVICES%"
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop %SERVICES%

call :print_success "%TARGET% services stopped successfully!"
goto :eof

:restart_services
call :print_header "Restarting %TARGET% services"
call :get_services %TARGET%
if errorlevel 1 exit /b 1

%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop %SERVICES%
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" up -d %SERVICES%

call :print_success "%TARGET% services restarted successfully!"
goto :eof

:show_logs
:: Support multiple targets for logs
set "LOG_TARGETS="
set "ALL_LOG_SERVICES="

:: Collect all targets from arguments (starting from %2)
shift
:collect_log_targets
if "%~1"=="" goto :process_log_targets
set "LOG_TARGETS=!LOG_TARGETS! %~1"
shift
goto :collect_log_targets

:process_log_targets
:: If no targets specified, default to all
if "!LOG_TARGETS!"=="" set "LOG_TARGETS=all"

:: Collect services from all specified targets
for %%t in (!LOG_TARGETS!) do (
    call :get_services %%t
    if errorlevel 1 exit /b 1
    set "ALL_LOG_SERVICES=!ALL_LOG_SERVICES! !SERVICES!"
)

call :print_header "Showing logs for:!LOG_TARGETS!"
call :print_info "Services:!ALL_LOG_SERVICES!"

%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" logs -f !ALL_LOG_SERVICES!
goto :eof

:show_status
call :print_header "Service Status"
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" ps
goto :eof

:clean
call :print_header "Cleaning up %TARGET%"

if "%TARGET%"=="all" (
    call :print_warning "This will remove all containers, anonymous volumes, and build cache."
    set /p "CONFIRM=Are you sure? (y/N): "
    if /i not "!CONFIRM!"=="y" (
        call :print_info "Cleanup cancelled."
        exit /b 0
    )
    
    call :print_info "Stopping all services..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" down -v --remove-orphans
    
    call :print_info "Pruning build cache..."
    docker builder prune -f 2>nul
    
    call :print_success "Full cleanup completed!"
) else (
    call :get_services %TARGET%
    if errorlevel 1 exit /b 1
    
    call :print_info "Stopping and removing %TARGET% services..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop %SERVICES%
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" rm -f %SERVICES%
    call :print_success "%TARGET% cleanup completed!"
)
goto :eof

:install_deps
call :print_header "Installing dependencies for %TARGET%"

if "%TARGET%"=="middleware" (
    call :print_info "Middleware services don't require dependency installation."
    goto :eof
)

if "%TARGET%"=="api" (
    call :print_info "Installing Go dependencies..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" exec gaap-api go mod download 2>nul || (
        cd gaap-api
        go mod download
        cd ..
    )
    call :print_success "Go dependencies installed!"
    goto :install_deps_done
)

if "%TARGET%"=="web" (
    call :print_info "Installing Node.js dependencies..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop gaap-web 2>nul
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" rm -f gaap-web 2>nul
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" build --no-cache gaap-web
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" up -d gaap-web
    call :print_success "Node.js dependencies installed!"
    goto :install_deps_done
)

if "%TARGET%"=="all" (
    call :print_info "Installing Go dependencies..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" exec gaap-api go mod download 2>nul || (
        cd gaap-api
        go mod download
        cd ..
    )
    call :print_success "Go dependencies installed!"
    
    call :print_info "Installing Node.js dependencies..."
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop gaap-web 2>nul
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" rm -f gaap-web 2>nul
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" build --no-cache gaap-web
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" up -d gaap-web
    call :print_success "Node.js dependencies installed!"
)

:install_deps_done
call :print_success "Dependencies installation completed!"
goto :eof

:rebuild
call :print_header "Rebuilding %TARGET% services"
call :get_services %TARGET%
if errorlevel 1 exit /b 1

call :print_info "Services: %SERVICES%"

:: Stop and remove containers to clear anonymous volumes
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" stop %SERVICES%
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" rm -f %SERVICES%

:: Rebuild images
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" build %SERVICES%

:: Start services
%DOCKER_COMPOSE% -f "%COMPOSE_FILE%" up -d %SERVICES%

call :print_success "%TARGET% services rebuilt and started!"
call :print_info "Hot-reload is active. Changes to source files will be reflected automatically."
goto :eof

:exec_cmd
set "EXEC_TARGET=%~2"
set "EXEC_CMD="

:: Build command from remaining arguments
shift
shift
:build_cmd_loop
if "%~1"=="" goto :exec_cmd_run
set "EXEC_CMD=!EXEC_CMD! %~1"
shift
goto :build_cmd_loop

:exec_cmd_run
if "!EXEC_CMD!"=="" (
    call :print_error "No command specified."
    exit /b 1
)

if "%EXEC_TARGET%"=="api" (
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" exec gaap-api !EXEC_CMD!
) else if "%EXEC_TARGET%"=="web" (
    %DOCKER_COMPOSE% -f "%COMPOSE_FILE%" exec gaap-web !EXEC_CMD!
) else (
    call :print_error "exec only supports 'api' or 'web' targets"
    exit /b 1
)
goto :eof

:show_help
echo.
echo GAAP Development Environment Management Script
echo.
echo Usage:
echo     start-dev.bat ^<command^> [target]
echo.
echo Commands:
echo     start [target]      Start services (default: all)
echo     stop [target]       Stop services (default: all)
echo     restart [target]    Restart services (default: all)
echo     logs [targets...]   Show service logs, supports multiple (default: all)
echo     status              Show service status
echo     clean [target]      Clean up containers and volumes (default: all)
echo     install [target]    Install/reinstall dependencies (default: all)
echo     rebuild [target]    Rebuild and restart services (default: all)
echo     exec ^<target^> ^<cmd^> Execute command in container (api/web only)
echo     help                Show this help message
echo.
echo Targets:
echo     middleware          PostgreSQL, Redis, RabbitMQ, Caddy
echo     api                 GAAP API (GoFrame backend)
echo     web                 GAAP Web (Next.js frontend)
echo     all                 All services (default)
echo.
echo Examples:
echo     start-dev.bat start                    # Start all services
echo     start-dev.bat start middleware         # Start only middleware
echo     start-dev.bat restart web              # Restart web service
echo     start-dev.bat logs api web             # View API and web logs together
echo     start-dev.bat clean web                # Clean web service
echo     start-dev.bat install web              # Reinstall npm dependencies
echo     start-dev.bat rebuild api              # Rebuild API service
echo     start-dev.bat exec api go test ./...   # Run tests in API container
echo     start-dev.bat exec web npm run lint    # Run linting in web container
echo.
echo Hot-Reload:
echo     - API: Uses 'air' for automatic Go rebuilds
echo     - Web: Uses Next.js built-in hot-reload (Turbopack)
echo.
echo Notes:
echo     - Source code is mounted into containers for hot-reload
echo     - Use 'install' or 'rebuild' to refresh dependencies
echo     - Use 'clean' to remove containers and anonymous volumes
echo.
goto :eof

endlocal
