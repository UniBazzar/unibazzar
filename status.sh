#!/bin/bash
# UniBazzar Project Status Dashboard
# Shows comprehensive overview of project health, services, and development metrics

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$PROJECT_ROOT/services"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_subheader() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "  ${GREEN}✓${NC} $message" ;;
        "warning") echo -e "  ${YELLOW}⚠${NC} $message" ;;
        "error") echo -e "  ${RED}✗${NC} $message" ;;
        "info") echo -e "  ${BLUE}ℹ${NC} $message" ;;
    esac
}

# Function to check if a service is running
check_service_status() {
    local service=$1
    local port=$2
    
    if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "running"
    elif docker ps --format "table {{.Names}}" | grep -q "$service"; then
        echo "container"
    else
        echo "stopped"
    fi
}

# Function to count lines of code
count_lines_of_code() {
    local dir=$1
    local extensions=$2
    
    find "$dir" -type f \( $extensions \) -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.git/*" -not -path "*/coverage/*" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0"
}

# Function to get git statistics
get_git_stats() {
    cd "$PROJECT_ROOT"
    
    local total_commits=$(git rev-list --all --count 2>/dev/null || echo "0")
    local contributors=$(git shortlog -sn --all | wc -l 2>/dev/null || echo "0")
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local last_commit=$(git log -1 --format="%cr" 2>/dev/null || echo "unknown")
    
    echo "$total_commits|$contributors|$current_branch|$last_commit"
}

# Function to check test coverage
check_coverage() {
    local service_dir=$1
    local coverage_file=""
    
    if [ -f "$service_dir/coverage.out" ]; then
        coverage_file="coverage.out"
    elif [ -f "$service_dir/coverage/lcov.info" ]; then
        coverage_file="coverage/lcov.info"
    fi
    
    if [ -n "$coverage_file" ] && [ -f "$service_dir/$coverage_file" ]; then
        echo "available"
    else
        echo "none"
    fi
}

# Function to check dependencies
check_dependencies() {
    local service_dir=$1
    local outdated=0
    
    cd "$service_dir"
    
    if [ -f "go.mod" ]; then
        if command -v go >/dev/null 2>&1; then
            outdated=$(go list -u -m all 2>/dev/null | grep -c "\[" || echo "0")
        fi
    elif [ -f "requirements.txt" ]; then
        if command -v pip >/dev/null 2>&1; then
            outdated=$(pip list --outdated --format=json 2>/dev/null | jq length 2>/dev/null || echo "0")
        fi
    elif [ -f "package.json" ]; then
        if command -v npm >/dev/null 2>&1; then
            outdated=$(npm outdated --json 2>/dev/null | jq 'keys | length' 2>/dev/null || echo "0")
        fi
    fi
    
    cd - >/dev/null
    echo "$outdated"
}

# Main dashboard function
show_dashboard() {
    clear
    
    echo -e "${BOLD}${PURPLE}"
    cat << 'EOF'
 _    _       _ ____
| |  | |     (_)  _ \
| |  | |_ __  _| |_) | __ _ __________ _ _ __
| |  | | '_ \| |  _ < / _` |_  /_  / _` | '__|
| |__| | | | | | |_) | (_| |/ / / / (_| | |
 \____/|_| |_|_|____/ \__,_/___/___\__,_|_|

EOF
    echo -e "${NC}"
    
    echo -e "${BOLD}${BLUE}📊 UniBazzar Project Dashboard${NC}"
    echo -e "${BLUE}Generated: $(date)${NC}"
    echo
    
    # Project Overview
    print_header "🏗️  PROJECT OVERVIEW"
    
    local git_stats=$(get_git_stats)
    local total_commits=$(echo "$git_stats" | cut -d'|' -f1)
    local contributors=$(echo "$git_stats" | cut -d'|' -f2)
    local current_branch=$(echo "$git_stats" | cut -d'|' -f3)
    local last_commit=$(echo "$git_stats" | cut -d'|' -f4)
    
    print_status "info" "Current branch: $current_branch"
    print_status "info" "Total commits: $total_commits"
    print_status "info" "Contributors: $contributors"
    print_status "info" "Last commit: $last_commit"
    echo
    
    # Development Environment
    print_header "🔧 DEVELOPMENT ENVIRONMENT"
    
    # Check required tools
    local tools=("docker" "docker-compose" "git" "curl" "jq")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=$(eval "$tool --version 2>/dev/null | head -1" || echo "unknown")
            print_status "success" "$tool: $version"
        else
            print_status "error" "$tool: Not installed"
        fi
    done
    echo
    
    # Infrastructure Status
    print_header "🚀 INFRASTRUCTURE STATUS"
    
    # Check Docker containers
    if command -v docker >/dev/null 2>&1; then
        local containers=(
            "postgres:5432"
            "redis:6379"
            "rabbitmq:5672"
            "jaeger:16686"
            "prometheus:9090"
            "grafana:3000"
        )
        
        for container in "${containers[@]}"; do
            local name=$(echo "$container" | cut -d':' -f1)
            local port=$(echo "$container" | cut -d':' -f2)
            
            if docker ps --format "table {{.Names}}" | grep -q "$name"; then
                if curl -s "http://localhost:$port" >/dev/null 2>&1; then
                    print_status "success" "$name: Running and responding"
                else
                    print_status "warning" "$name: Container running but not responding"
                fi
            else
                print_status "error" "$name: Not running"
            fi
        done
    else
        print_status "error" "Docker not available"
    fi
    echo
    
    # Services Status
    print_header "🔬 MICROSERVICES STATUS"
    
    local services=(
        "auth-service:8080"
        "listing-service:8081"
        "order-service:8082"
        "notification-service:8083"
        "ai-service:8000"
        "chat-gateway:3000"
    )
    
    for service_info in "${services[@]}"; do
        local service=$(echo "$service_info" | cut -d':' -f1)
        local port=$(echo "$service_info" | cut -d':' -f2)
        local service_dir="$SERVICES_DIR/$service"
        
        print_subheader "$service"
        
        if [ -d "$service_dir" ]; then
            # Service status
            local status=$(check_service_status "$service" "$port")
            case $status in
                "running") print_status "success" "Status: Running on port $port" ;;
                "container") print_status "warning" "Status: Container running but health check failed" ;;
                "stopped") print_status "error" "Status: Not running" ;;
            esac
            
            # Code metrics
            local go_lines=$(count_lines_of_code "$service_dir" "-name '*.go'")
            local py_lines=$(count_lines_of_code "$service_dir" "-name '*.py'")
            local ts_lines=$(count_lines_of_code "$service_dir" "-name '*.ts' -o -name '*.js'")
            
            local total_lines=$((go_lines + py_lines + ts_lines))
            if [ $total_lines -gt 0 ]; then
                print_status "info" "Lines of code: $total_lines"
            fi
            
            # Test coverage
            local coverage=$(check_coverage "$service_dir")
            if [ "$coverage" = "available" ]; then
                print_status "success" "Test coverage: Available"
            else
                print_status "warning" "Test coverage: Not available"
            fi
            
            # Dependencies
            local outdated=$(check_dependencies "$service_dir")
            if [ "$outdated" -eq 0 ]; then
                print_status "success" "Dependencies: Up to date"
            else
                print_status "warning" "Dependencies: $outdated outdated packages"
            fi
            
        else
            print_status "error" "Service directory not found"
        fi
        echo
    done
    
    # Development Metrics
    print_header "📈 DEVELOPMENT METRICS"
    
    # Total lines of code across all services
    local total_go_lines=0
    local total_py_lines=0
    local total_ts_lines=0
    
    for service_dir in "$SERVICES_DIR"/*; do
        if [ -d "$service_dir" ]; then
            total_go_lines=$((total_go_lines + $(count_lines_of_code "$service_dir" "-name '*.go'")))
            total_py_lines=$((total_py_lines + $(count_lines_of_code "$service_dir" "-name '*.py'")))
            total_ts_lines=$((total_ts_lines + $(count_lines_of_code "$service_dir" "-name '*.ts' -o -name '*.js'")))
        fi
    done
    
    local total_code_lines=$((total_go_lines + total_py_lines + total_ts_lines))
    
    print_status "info" "Total lines of code: $total_code_lines"
    print_status "info" "  - Go: $total_go_lines lines"
    print_status "info" "  - Python: $total_py_lines lines"
    print_status "info" "  - TypeScript/JavaScript: $total_ts_lines lines"
    
    # File counts
    local total_files=$(find "$PROJECT_ROOT" -type f -name "*.go" -o -name "*.py" -o -name "*.ts" -o -name "*.js" | grep -v node_modules | grep -v vendor | wc -l)
    print_status "info" "Source files: $total_files"
    
    # Documentation files
    local doc_files=$(find "$PROJECT_ROOT" -type f -name "*.md" | wc -l)
    print_status "info" "Documentation files: $doc_files"
    
    echo
    
    # Recent Activity
    print_header "🕐 RECENT ACTIVITY"
    
    cd "$PROJECT_ROOT"
    print_status "info" "Recent commits:"
    git log --oneline -5 --format="    %cr - %s (%an)" 2>/dev/null || echo "    No git history available"
    echo
    
    # Health Recommendations
    print_header "💡 RECOMMENDATIONS"
    
    local recommendations=()
    
    # Check if services are running
    local running_services=0
    for service_info in "${services[@]}"; do
        local service=$(echo "$service_info" | cut -d':' -f1)
        local port=$(echo "$service_info" | cut -d':' -f2)
        local status=$(check_service_status "$service" "$port")
        if [ "$status" = "running" ]; then
            ((running_services++))
        fi
    done
    
    if [ $running_services -lt 3 ]; then
        recommendations+=("Start development environment with: docker-compose up -d")
    fi
    
    # Check for test coverage
    local services_with_coverage=0
    for service_dir in "$SERVICES_DIR"/*; do
        if [ -d "$service_dir" ]; then
            local coverage=$(check_coverage "$service_dir")
            if [ "$coverage" = "available" ]; then
                ((services_with_coverage++))
            fi
        fi
    done
    
    if [ $services_with_coverage -lt 3 ]; then
        recommendations+=("Run tests with coverage: ./tools/testing/run-tests.sh --coverage")
    fi
    
    # Check git status
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        recommendations+=("Commit pending changes: git status shows uncommitted files")
    fi
    
    # Display recommendations
    if [ ${#recommendations[@]} -gt 0 ]; then
        for rec in "${recommendations[@]}"; do
            print_status "warning" "$rec"
        done
    else
        print_status "success" "Project health looks good! 🎉"
    fi
    
    echo
    print_header "🚀 QUICK ACTIONS"
    echo -e "  ${GREEN}./setup.sh${NC}                           - Initialize development environment"
    echo -e "  ${GREEN}docker-compose up -d${NC}                 - Start all infrastructure services"
    echo -e "  ${GREEN}./tools/testing/run-tests.sh --coverage${NC} - Run all tests with coverage"
    echo -e "  ${GREEN}./tools/db/migrate.sh up${NC}             - Apply database migrations"
    echo -e "  ${GREEN}git status${NC}                           - Check repository status"
    echo
    
    cd - >/dev/null
}

# Parse command line arguments
WATCH_MODE=false
REFRESH_INTERVAL=30

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "UniBazzar Project Dashboard"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -w, --watch     Watch mode (refresh every 30 seconds)"
            echo "  -i, --interval  Refresh interval in seconds (default: 30)"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        -i|--interval)
            REFRESH_INTERVAL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
if [ "$WATCH_MODE" = true ]; then
    while true; do
        show_dashboard
        echo -e "${YELLOW}⏱️  Refreshing in $REFRESH_INTERVAL seconds... (Ctrl+C to exit)${NC}"
        sleep "$REFRESH_INTERVAL"
    done
else
    show_dashboard
fi
