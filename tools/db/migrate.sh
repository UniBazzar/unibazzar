#!/bin/bash
# Database migration utility for UniBazzar

set -e

# Configuration
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-unibazzar}
DB_USER=${DB_USER:-postgres}
# Do not set a real default password. Leave empty so callers must supply via env.
DB_PASSWORD=${DB_PASSWORD:-""}
MIGRATIONS_DIR=${MIGRATIONS_DIR:-"./migrations"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
usage() {
    cat << EOF
UniBazzar Database Migration Tool

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    up [N]          Apply N migrations (default: all)
    down [N]        Rollback N migrations (default: 1)
    status          Show migration status
    create NAME     Create a new migration file
    reset           Reset database to clean state
    version         Show current migration version

Options:
    -h, --help      Show this help message
    -d, --dir DIR   Migrations directory (default: ./migrations)
    -H, --host HOST Database host (default: localhost)
    -p, --port PORT Database port (default: 5432)
    -U, --user USER Database user (default: postgres)
    -n, --name NAME Database name (default: unibazzar)

Environment Variables:
    DB_HOST         Database host
    DB_PORT         Database port  
    DB_NAME         Database name
    DB_USER         Database user
    DB_PASSWORD     Database password

Examples:
    $0 up                    Apply all pending migrations
    $0 up 5                  Apply next 5 migrations
    $0 down                  Rollback last migration
    $0 down 3                Rollback last 3 migrations
    $0 status                Show current status
    $0 create add_users      Create new migration file
    $0 reset                 Reset database

EOF
}

# Function to connect to database
connect_db() {
    export PGPASSWORD="$DB_PASSWORD"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null
}

# Function to execute SQL
execute_sql() {
    local sql="$1"
    export PGPASSWORD="$DB_PASSWORD"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql"
}

# Function to execute SQL file
execute_sql_file() {
    local file="$1"
    export PGPASSWORD="$DB_PASSWORD"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"
}

# Function to initialize migration tracking
init_migrations_table() {
    print_info "Initializing migrations table..."
    execute_sql "
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version VARCHAR(14) PRIMARY KEY,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    "
    print_success "Migrations table ready"
}

# Function to get current migration version
get_current_version() {
    execute_sql "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;" -t -A 2>/dev/null | head -n 1 || echo ""
}

# Function to get applied migrations
get_applied_migrations() {
    execute_sql "SELECT version FROM schema_migrations ORDER BY version;" -t -A 2>/dev/null || true
}

# Function to get pending migrations
get_pending_migrations() {
    local applied_migrations=$(mktemp)
    get_applied_migrations > "$applied_migrations"
    
    find "$MIGRATIONS_DIR" -name "*.sql" -type f | grep -E '[0-9]{14}_.*\.sql$' | sort | while read -r file; do
        local version=$(basename "$file" .sql | cut -d'_' -f1)
        if ! grep -q "^$version$" "$applied_migrations" 2>/dev/null; then
            echo "$file"
        fi
    done
    
    rm -f "$applied_migrations"
}

# Function to create new migration
create_migration() {
    local name="$1"
    
    if [ -z "$name" ]; then
        print_error "Migration name is required"
        echo "Usage: $0 create MIGRATION_NAME"
        exit 1
    fi
    
    # Generate timestamp
    local timestamp=$(date +"%Y%m%d%H%M%S")
    local filename="${timestamp}_${name}.sql"
    local filepath="$MIGRATIONS_DIR/$filename"
    
    # Create migrations directory if it doesn't exist
    mkdir -p "$MIGRATIONS_DIR"
    
    # Create migration file with template
    cat > "$filepath" << EOF
-- Migration: $name
-- Created: $(date)
-- Description: Add description of what this migration does

-- +migrate Up
-- SQL for applying the migration goes here


-- +migrate Down  
-- SQL for rolling back the migration goes here

EOF
    
    print_success "Created migration: $filepath"
    echo "Edit the file to add your SQL statements"
}

# Function to apply migrations
migrate_up() {
    local limit="$1"
    
    print_info "Checking database connection..."
    if ! connect_db; then
        print_error "Cannot connect to database"
        exit 1
    fi
    
    init_migrations_table
    
    local pending_migrations=()
    while IFS= read -r -d '' file; do
        pending_migrations+=("$file")
    done < <(get_pending_migrations | head -n "${limit:-999}" | tr '\n' '\0')
    
    if [ ${#pending_migrations[@]} -eq 0 ]; then
        print_info "No pending migrations"
        return 0
    fi
    
    print_info "Found ${#pending_migrations[@]} pending migration(s)"
    
    for migration_file in "${pending_migrations[@]}"; do
        local version=$(basename "$migration_file" .sql | cut -d'_' -f1)
        local name=$(basename "$migration_file" .sql | cut -d'_' -f2-)
        
        print_info "Applying migration $version: $name"
        
        # Extract UP section from migration file
        local up_sql=$(awk '/-- \+migrate Up/,/-- \+migrate Down/ {if (!/-- \+migrate/) print}' "$migration_file")
        
        if [ -z "$up_sql" ]; then
            print_warning "No UP section found in $migration_file, executing entire file"
            execute_sql_file "$migration_file"
        else
            echo "$up_sql" | execute_sql "$(cat)"
        fi
        
        # Record migration as applied
        execute_sql "INSERT INTO schema_migrations (version) VALUES ('$version');"
        
        print_success "Applied migration $version"
    done
    
    print_success "All migrations applied successfully"
}

# Function to rollback migrations
migrate_down() {
    local count="${1:-1}"
    
    print_info "Checking database connection..."
    if ! connect_db; then
        print_error "Cannot connect to database"
        exit 1
    fi
    
    init_migrations_table
    
    # Get last N applied migrations
    local migrations_to_rollback=()
    while IFS= read -r version; do
        migrations_to_rollback+=("$version")
    done < <(execute_sql "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT $count;" -t -A 2>/dev/null)
    
    if [ ${#migrations_to_rollback[@]} -eq 0 ]; then
        print_info "No migrations to rollback"
        return 0
    fi
    
    print_info "Rolling back ${#migrations_to_rollback[@]} migration(s)"
    
    for version in "${migrations_to_rollback[@]}"; do
        local migration_file
        migration_file=$(find "$MIGRATIONS_DIR" -name "${version}_*.sql" -type f | head -n 1)
        
        if [ ! -f "$migration_file" ]; then
            print_error "Migration file not found for version $version"
            continue
        fi
        
        local name=$(basename "$migration_file" .sql | cut -d'_' -f2-)
        print_info "Rolling back migration $version: $name"
        
        # Extract DOWN section from migration file
        local down_sql=$(awk '/-- \+migrate Down/,EOF {if (!/-- \+migrate Down/) print}' "$migration_file")
        
        if [ -z "$down_sql" ]; then
            print_warning "No DOWN section found in $migration_file"
            print_warning "Manual rollback may be required"
        else
            echo "$down_sql" | execute_sql "$(cat)"
        fi
        
        # Remove migration from applied list
        execute_sql "DELETE FROM schema_migrations WHERE version = '$version';"
        
        print_success "Rolled back migration $version"
    done
    
    print_success "All migrations rolled back successfully"
}

# Function to show migration status
show_status() {
    print_info "Migration Status"
    echo
    
    if ! connect_db; then
        print_error "Cannot connect to database"
        exit 1
    fi
    
    init_migrations_table
    
    local current_version
    current_version=$(get_current_version)
    
    if [ -z "$current_version" ]; then
        print_info "Current version: None (fresh database)"
    else
        print_info "Current version: $current_version"
    fi
    
    echo
    print_info "Applied migrations:"
    local applied_count=0
    while IFS= read -r version; do
        if [ -n "$version" ]; then
            local migration_file
            migration_file=$(find "$MIGRATIONS_DIR" -name "${version}_*.sql" -type f | head -n 1)
            local name=""
            if [ -f "$migration_file" ]; then
                name=$(basename "$migration_file" .sql | cut -d'_' -f2-)
            fi
            echo "  ✓ $version: $name"
            ((applied_count++))
        fi
    done < <(get_applied_migrations)
    
    if [ $applied_count -eq 0 ]; then
        echo "  (none)"
    fi
    
    echo
    print_info "Pending migrations:"
    local pending_count=0
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local version=$(basename "$file" .sql | cut -d'_' -f1)
            local name=$(basename "$file" .sql | cut -d'_' -f2-)
            echo "  → $version: $name"
            ((pending_count++))
        fi
    done < <(get_pending_migrations)
    
    if [ $pending_count -eq 0 ]; then
        echo "  (none)"
    fi
    
    echo
    print_info "Summary: $applied_count applied, $pending_count pending"
}

# Function to reset database
reset_database() {
    print_warning "This will completely reset the database!"
    read -p "Are you sure? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Reset cancelled"
        exit 0
    fi
    
    print_info "Resetting database..."
    
    if ! connect_db; then
        print_error "Cannot connect to database"
        exit 1
    fi
    
    # Drop all tables
    local tables
    tables=$(execute_sql "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" -t -A 2>/dev/null || true)
    
    if [ -n "$tables" ]; then
        print_info "Dropping existing tables..."
        echo "$tables" | while IFS= read -r table; do
            if [ -n "$table" ]; then
                execute_sql "DROP TABLE IF EXISTS \"$table\" CASCADE;"
                print_info "Dropped table: $table"
            fi
        done
    fi
    
    print_success "Database reset complete"
    print_info "Run '$0 up' to apply all migrations"
}

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        up|down|status|create|reset|version)
            COMMAND=$1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -d|--dir)
            MIGRATIONS_DIR="$2"
            shift 2
            ;;
        -H|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -U|--user)
            DB_USER="$2"
            shift 2
            ;;
        -n|--name)
            DB_NAME="$2"
            shift 2
            ;;
        *)
            if [ -z "$COMMAND" ]; then
                print_error "Unknown command: $1"
                usage
                exit 1
            else
                # This is likely an argument for the command
                break
            fi
            ;;
    esac
done

# Execute command
case $COMMAND in
    up)
        migrate_up "$1"
        ;;
    down)
        migrate_down "$1"
        ;;
    status)
        show_status
        ;;
    create)
        create_migration "$1"
        ;;
    reset)
        reset_database
        ;;
    version)
        current_version=$(get_current_version)
        if [ -z "$current_version" ]; then
            echo "No migrations applied"
        else
            echo "$current_version"
        fi
        ;;
    "")
        print_error "No command specified"
        usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
