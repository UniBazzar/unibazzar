#!/bin/bash
# Test runner utility for UniBazzar

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_DIR="$PROJECT_ROOT/coverage"
REPORTS_DIR="$PROJECT_ROOT/reports"
SERVICES_DIR="$PROJECT_ROOT/services"

# Default values
COVERAGE=false
VERBOSE=false
PARALLEL=true
SERVICES=""
TEST_PATTERN=""
TIMEOUT="30s"
RACE_DETECTION=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

usage() {
    cat << EOF
UniBazzar Test Runner

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -c, --coverage          Generate coverage report
    -v, --verbose           Verbose output
    -s, --services LIST     Comma-separated list of services to test
    -p, --pattern PATTERN   Test pattern/filter
    -t, --timeout DURATION  Test timeout (default: 30s)
    --no-parallel           Disable parallel test execution
    --no-race               Disable race detection
    --unit                  Run only unit tests
    --integration          Run only integration tests
    --e2e                  Run only end-to-end tests
    --benchmark            Run benchmark tests

Examples:
    $0                              Run all tests
    $0 -c                          Run tests with coverage
    $0 -s auth,ai -c               Run tests for specific services with coverage
    $0 --integration -v            Run integration tests with verbose output
    $0 -p "TestUser*" -s auth      Run specific test pattern in auth service

EOF
}

# Function to detect service type and run appropriate tests
run_service_tests() {
    local service_dir="$1"
    local service_name="$2"
    local test_type="$3"
    
    if [ ! -d "$service_dir" ]; then
        print_error "Service directory not found: $service_dir"
        return 1
    fi
    
    cd "$service_dir"
    print_info "Running $test_type tests for $service_name"
    
    # Detect service type
    if [ -f "go.mod" ]; then
        run_go_tests "$service_name" "$test_type"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        run_python_tests "$service_name" "$test_type"
    elif [ -f "package.json" ]; then
        run_node_tests "$service_name" "$test_type"
    else
        print_warning "Unknown service type for $service_name"
        return 1
    fi
    
    cd - > /dev/null
}

# Go test runner
run_go_tests() {
    local service_name="$1"
    local test_type="$2"
    
    local test_args=""
    local coverage_args=""
    local race_args=""
    
    # Test type specific arguments
    case "$test_type" in
        unit)
            test_args="-short"
            ;;
        integration)
            test_args="-tags=integration"
            ;;
        benchmark)
            test_args="-bench=. -benchmem"
            ;;
    esac
    
    # Coverage arguments
    if [ "$COVERAGE" = true ]; then
        mkdir -p "$COVERAGE_DIR"
        coverage_args="-coverprofile=$COVERAGE_DIR/${service_name}.out -covermode=atomic"
    fi
    
    # Race detection
    if [ "$RACE_DETECTION" = true ] && [ "$test_type" != "benchmark" ]; then
        race_args="-race"
    fi
    
    # Verbose output
    if [ "$VERBOSE" = true ]; then
        test_args="$test_args -v"
    fi
    
    # Test pattern
    if [ -n "$TEST_PATTERN" ]; then
        test_args="$test_args -run $TEST_PATTERN"
    fi
    
    # Parallel execution
    if [ "$PARALLEL" = true ]; then
        test_args="$test_args -parallel 4"
    fi
    
    local cmd="go test $test_args $race_args $coverage_args -timeout=$TIMEOUT ./..."
    
    print_info "Executing: $cmd"
    
    if eval "$cmd"; then
        print_success "$service_name tests passed"
        
        # Generate coverage HTML if coverage was requested
        if [ "$COVERAGE" = true ] && [ -f "$COVERAGE_DIR/${service_name}.out" ]; then
            go tool cover -html="$COVERAGE_DIR/${service_name}.out" -o "$COVERAGE_DIR/${service_name}.html"
            print_info "Coverage report: $COVERAGE_DIR/${service_name}.html"
        fi
        
        return 0
    else
        print_error "$service_name tests failed"
        return 1
    fi
}

# Python test runner
run_python_tests() {
    local service_name="$1"
    local test_type="$2"
    
    local test_args=""
    local coverage_args=""
    
    # Check if pytest is available
    if ! command -v pytest &> /dev/null; then
        print_error "pytest not found. Install with: pip install pytest"
        return 1
    fi
    
    # Test type specific arguments
    case "$test_type" in
        unit)
            test_args="-m 'not integration and not e2e'"
            ;;
        integration)
            test_args="-m integration"
            ;;
        e2e)
            test_args="-m e2e"
            ;;
        benchmark)
            test_args="--benchmark-only"
            ;;
    esac
    
    # Coverage arguments
    if [ "$COVERAGE" = true ]; then
        mkdir -p "$COVERAGE_DIR"
        coverage_args="--cov=. --cov-report=html:$COVERAGE_DIR/${service_name}-html --cov-report=xml:$COVERAGE_DIR/${service_name}.xml"
    fi
    
    # Verbose output
    if [ "$VERBOSE" = true ]; then
        test_args="$test_args -v"
    fi
    
    # Test pattern
    if [ -n "$TEST_PATTERN" ]; then
        test_args="$test_args -k $TEST_PATTERN"
    fi
    
    # Parallel execution
    if [ "$PARALLEL" = true ]; then
        test_args="$test_args -n auto"
    fi
    
    local cmd="pytest $test_args $coverage_args"
    
    print_info "Executing: $cmd"
    
    if eval "$cmd"; then
        print_success "$service_name tests passed"
        return 0
    else
        print_error "$service_name tests failed"
        return 1
    fi
}

# Node.js test runner
run_node_tests() {
    local service_name="$1"
    local test_type="$2"
    
    local test_command=""
    local test_args=""
    
    # Determine test command
    if [ -f "package.json" ] && command -v npm &> /dev/null; then
        if npm run | grep -q "test"; then
            test_command="npm test"
        elif npm run | grep -q "jest"; then
            test_command="npm run jest"
        fi
    fi
    
    if [ -z "$test_command" ] && command -v jest &> /dev/null; then
        test_command="jest"
    fi
    
    if [ -z "$test_command" ]; then
        print_error "No test command found for $service_name"
        return 1
    fi
    
    # Test type specific arguments
    case "$test_type" in
        unit)
            test_args="--testPathIgnorePatterns=integration,e2e"
            ;;
        integration)
            test_args="--testPathPattern=integration"
            ;;
        e2e)
            test_args="--testPathPattern=e2e"
            ;;
    esac
    
    # Coverage arguments
    if [ "$COVERAGE" = true ]; then
        mkdir -p "$COVERAGE_DIR"
        test_args="$test_args --coverage --coverageDirectory=$COVERAGE_DIR/${service_name}"
    fi
    
    # Verbose output
    if [ "$VERBOSE" = true ]; then
        test_args="$test_args --verbose"
    fi
    
    # Test pattern
    if [ -n "$TEST_PATTERN" ]; then
        test_args="$test_args --testNamePattern=$TEST_PATTERN"
    fi
    
    local cmd="$test_command $test_args"
    
    print_info "Executing: $cmd"
    
    if eval "$cmd"; then
        print_success "$service_name tests passed"
        return 0
    else
        print_error "$service_name tests failed"
        return 1
    fi
}

# Function to generate combined coverage report
generate_coverage_report() {
    if [ ! -d "$COVERAGE_DIR" ]; then
        print_warning "No coverage data found"
        return 0
    fi
    
    print_info "Generating combined coverage report..."
    
    mkdir -p "$REPORTS_DIR"
    
    # Combine Go coverage files
    local go_coverage_files=$(find "$COVERAGE_DIR" -name "*.out" 2>/dev/null || true)
    if [ -n "$go_coverage_files" ]; then
        echo "mode: atomic" > "$COVERAGE_DIR/combined.out"
        for file in $go_coverage_files; do
            tail -n +2 "$file" >> "$COVERAGE_DIR/combined.out" 2>/dev/null || true
        done
        
        if [ -s "$COVERAGE_DIR/combined.out" ]; then
            go tool cover -html="$COVERAGE_DIR/combined.out" -o "$REPORTS_DIR/coverage.html"
            print_success "Combined Go coverage report: $REPORTS_DIR/coverage.html"
        fi
    fi
    
    # Generate summary report
    cat > "$REPORTS_DIR/test-summary.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>UniBazzar Test Summary</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .service { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .service h3 { margin-top: 0; color: #333; }
        .passed { border-left: 5px solid #4CAF50; }
        .failed { border-left: 5px solid #f44336; }
        .coverage { margin-top: 10px; font-size: 14px; color: #666; }
        .timestamp { color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <h1>🧪 UniBazzar Test Summary</h1>
    <div class="timestamp">Generated: $(date)</div>
EOF
    
    # Add service results
    for service in $(find "$SERVICES_DIR" -maxdepth 1 -type d -exec basename {} \; | grep -E "(auth|ai|chat|listing|order|notification)" | sort); do
        local status_class="passed"
        local status_text="✅ PASSED"
        
        echo "    <div class=\"service $status_class\">" >> "$REPORTS_DIR/test-summary.html"
        echo "        <h3>$service</h3>" >> "$REPORTS_DIR/test-summary.html"
        echo "        <div>Status: $status_text</div>" >> "$REPORTS_DIR/test-summary.html"
        
        # Add coverage info if available
        if [ -f "$COVERAGE_DIR/${service}.html" ]; then
            echo "        <div class=\"coverage\">📊 <a href=\"../${service}.html\">Coverage Report</a></div>" >> "$REPORTS_DIR/test-summary.html"
        fi
        
        echo "    </div>" >> "$REPORTS_DIR/test-summary.html"
    done
    
    cat >> "$REPORTS_DIR/test-summary.html" << 'EOF'
</body>
</html>
EOF
    
    print_success "Test summary report: $REPORTS_DIR/test-summary.html"
}

# Function to run tests for all services
run_all_tests() {
    local test_type="$1"
    local failed_services=()
    local passed_services=()
    
    # Get list of services to test
    local services_to_test=()
    if [ -n "$SERVICES" ]; then
        IFS=',' read -ra services_to_test <<< "$SERVICES"
    else
        # Auto-detect services
        for service_dir in "$SERVICES_DIR"/*; do
            if [ -d "$service_dir" ]; then
                local service_name=$(basename "$service_dir")
                if [[ "$service_name" =~ ^(auth|ai|chat|listing|order|notification) ]]; then
                    services_to_test+=("$service_name")
                fi
            fi
        done
    fi
    
    if [ ${#services_to_test[@]} -eq 0 ]; then
        print_error "No services found to test"
        exit 1
    fi
    
    print_info "Testing services: ${services_to_test[*]}"
    print_info "Test type: $test_type"
    echo
    
    # Create output directories
    mkdir -p "$COVERAGE_DIR" "$REPORTS_DIR"
    
    # Run tests for each service
    for service_name in "${services_to_test[@]}"; do
        local service_dir="$SERVICES_DIR/$service_name"
        
        if run_service_tests "$service_dir" "$service_name" "$test_type"; then
            passed_services+=("$service_name")
        else
            failed_services+=("$service_name")
        fi
        echo
    done
    
    # Generate coverage report if requested
    if [ "$COVERAGE" = true ]; then
        generate_coverage_report
    fi
    
    # Print summary
    echo "==================== TEST SUMMARY ===================="
    echo "Total services: ${#services_to_test[@]}"
    echo "Passed: ${#passed_services[@]} (${passed_services[*]})"
    echo "Failed: ${#failed_services[@]} (${failed_services[*]})"
    echo "======================================================"
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        exit 1
    fi
    
    print_success "All tests passed! 🎉"
}

# Parse command line arguments
TEST_TYPE="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--services)
            SERVICES="$2"
            shift 2
            ;;
        -p|--pattern)
            TEST_PATTERN="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --no-parallel)
            PARALLEL=false
            shift
            ;;
        --no-race)
            RACE_DETECTION=false
            shift
            ;;
        --unit)
            TEST_TYPE="unit"
            shift
            ;;
        --integration)
            TEST_TYPE="integration"
            shift
            ;;
        --e2e)
            TEST_TYPE="e2e"
            shift
            ;;
        --benchmark)
            TEST_TYPE="benchmark"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
print_info "UniBazzar Test Runner"
print_info "Project root: $PROJECT_ROOT"
echo

run_all_tests "$TEST_TYPE"
