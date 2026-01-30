#!/usr/bin/env bash

set -e # Exit on error

# Script metadata
SCRIPT_NAME="WordPress Docker Environment Manager"
SCRIPT_VERSION="2.0.0"
SCRIPT_AUTHOR="Enhanced with Gum"

# Default configuration settings
# Project settings
PROJECT_NAME=${PROJECT_NAME:-"wordpress"}
DOMAIN=${DOMAIN:-"wordpress.local"}
VITE_DEV_SERVER=${VITE_DEV_SERVER:-"vite.wordpress.local"}

# Docker images
DB_IMAGE=${DB_IMAGE:-"mariadb:latest"}
WP_IMAGE=${WP_IMAGE:-"wordpress:php8.4-fpm"}
WP_UNIT_TESTING_IMAGE=${WP_UNIT_TESTING_IMAGE:-"wordpress:php8.4-fpm"}
NGINX_IMAGE=${NGINX_IMAGE:-"nginx:alpine-slim"}
APACHE_WP_IMAGE=${APACHE_WP_IMAGE:-"wordpress:php8.4"}
NODE_IMAGE=${NODE_IMAGE:-"node:24-alpine"}
REDIS_IMAGE=${REDIS_IMAGE:-"redis:alpine"}
VITE_IMAGE=${VITE_IMAGE:-"vite-app:latest"}

# Directory paths
DATA_DIR=${DATA_DIR:-"./data"}
CONFIG_DIR=${CONFIG_DIR:-"./config"}
DOCKER_DIR=${DOCKER_DIR:-"./.docker"}

# Database settings
MYSQL_DATABASE=${MYSQL_DATABASE:-"wp"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"password"}
MYSQL_USER=${MYSQL_USER:-"wp"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"password"}

# WordPress settings
WP_TABLE_PREFIX=${WP_TABLE_PREFIX:-"wp_"}
WP_DEBUG=${WP_DEBUG:-"true"}
WP_DEBUG_DISPLAY=${WP_DEBUG_DISPLAY:-"true"}
WP_DEBUG_LOG=${WP_DEBUG_LOG:-"true"}
WP_SAVEQUERIES=${WP_SAVEQUERIES:-"true"}
WP_SCRIPT_DEBUG=${WP_SCRIPT_DEBUG:-"true"}

# Docker networks
DOCKER_DEV_NETWORK=${DOCKER_DEV_NETWORK:-"proxy"}
DOCKER_PROD_NETWORK=${DOCKER_PROD_NETWORK:-"proxy"}

# Container names
WP_CONTAINER=${WP_CONTAINER:-"wordpress"}
DB_CONTAINER=${DB_CONTAINER:-"db"}
WP_CLI_CONTAINER=${WP_CLI_CONTAINER:-"wp-cli"}
REDIS_CONTAINER=${REDIS_CONTAINER:-"redis"}
NGINX_CONTAINER=${NGINX_CONTAINER:-"nginx"}
VITE_CONTAINER=${VITE_CONTAINER:-"vite"}

# User settings
USER_ID=${USER_ID:-$(id -u)}
GROUP_ID=${GROUP_ID:-$(id -g)}

# Remote sync configuration
REMOTE_SSH_HOST=${REMOTE_SSH_HOST:-"remote-server"}
REMOTE_PROJECT_PATH=${REMOTE_PROJECT_PATH:-"~/web/example.com"}
REMOTE_DB_CONTAINER=${REMOTE_DB_CONTAINER:-"db_greatlife"}
REMOTE_DB_USER=${REMOTE_DB_USER:-"root"}
REMOTE_DB_PASSWORD=${REMOTE_DB_PASSWORD:-"password"}
REMOTE_DB_NAME=${REMOTE_DB_NAME:-"wp"}
LOCAL_DOMAIN=${LOCAL_DOMAIN:-"example.local"}
REMOTE_DOMAIN=${REMOTE_DOMAIN:-"example.com"}

# Proxy container settings
PROXY_CONTAINER_NAME=${PROXY_CONTAINER_NAME:-"proxy"}
PROXY_NETWORK=${PROXY_NETWORK:-"proxy"}
PROXY_CERTS_DIR=${PROXY_CERTS_DIR:-"${HOME}/certs"}
PROXY_IMAGE=${PROXY_IMAGE:-"nginxproxy/nginx-proxy:alpine"}
PROXY_CERT_FILE=${PROXY_CERT_FILE:-"allword.local.crt"}
PROXY_KEY_FILE=${PROXY_KEY_FILE:-"allword.local.key"}

# Configuration file path
CONFIG_FILE="./wordpress-docker.conf"

# Load configuration from file if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Enhanced styling with consistent colors
THEME_PRIMARY="#7C3AED" # Purple - main brand
THEME_SUCCESS="#10B981" # Green - success states
THEME_WARNING="#F59E0B" # Amber - warnings
THEME_ERROR="#EF4444"   # Red - errors
THEME_INFO="#3B82F6"    # Blue - information
THEME_MUTED="#6B7280"   # Gray - muted text

# Enhanced logging functions with better visual feedback
log_info() {
    gum style --foreground="$THEME_INFO" "ℹ INFO: $1"
}

log_success() {
    gum style --foreground="$THEME_SUCCESS" "✅ SUCCESS: $1"
}

log_warning() {
    gum style --foreground="$THEME_WARNING" "⚠️  WARNING: $1"
}

log_error() {
    gum style --foreground="$THEME_ERROR" "❌ ERROR: $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        gum style --foreground="$THEME_MUTED" "🐛 DEBUG: $1"
    fi
}

# Enhanced section headers
section_header() {
    gum style \
        --foreground="$THEME_PRIMARY" \
        --border="double" \
        --border-foreground="$THEME_PRIMARY" \
        --align="center" \
        --width=60 \
        --margin="1 0" \
        --padding="1 2" \
        "$1"
}

# Enhanced utility functions leveraging Gum's power
show_header() {
    clear
    section_header "$SCRIPT_NAME v$SCRIPT_VERSION"
    gum style --foreground="$THEME_MUTED" --align="center" "Enhanced with ✨ Gum for better UX"
    echo
}

# Enhanced input with validation and styling
gum_input_required() {
    local prompt="$1"
    local placeholder="$2"
    local value=""

    while [[ -z "$value" ]]; do
        value=$(gum input \
            --prompt="$prompt: " \
            --placeholder="$placeholder" \
            --width=50)

        if [[ -z "$value" ]]; then
            log_warning "This field is required. Please enter a value."
        fi
    done

    echo "$value"
}

gum_input_with_default() {
    local prompt="$1"
    local default="$2"
    local placeholder="${3:-$default}"

    local result
    result=$(gum input \
        --prompt="$prompt: " \
        --placeholder="$placeholder" \
        --value="$default" \
        --width=50)

    # Return default if empty
    echo "${result:-$default}"
}

# Enhanced confirmation with custom styling
gum_confirm_styled() {
    local prompt="$1"
    local default="${2:-true}"

    if [[ "$default" == "true" ]]; then
        gum confirm --default=true --prompt.foreground="$THEME_PRIMARY" "$prompt"
    else
        gum confirm --default=false --prompt.foreground="$THEME_PRIMARY" "$prompt"
    fi
}

# Progress indicators using Gum's spinner
run_with_spinner() {
    local title="$1"
    local command="$2"

    gum spin --spinner dot --title "$title" -- bash -c "$command"
}

# Enhanced menu with better styling
gum_menu_styled() {
    local title="$1"
    shift
    local options=("$@")

    gum choose \
        --header="$title" \
        --header.foreground="$THEME_PRIMARY" \
        --selected.foreground="$THEME_SUCCESS" \
        --cursor.foreground="$THEME_PRIMARY" \
        --height=15 \
        "${options[@]}"
}

# Legacy function for backward compatibility - now uses gum
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    gum_input_with_default "$prompt" "$default"
}

# Enhanced legacy menu function
gum_menu() {
    local title="$1"
    shift
    local options=("$@")

    # Add Back/Exit option if not present
    local has_exit=false
    for opt in "${options[@]}"; do
        if [[ "$opt" =~ (Back|Exit|Return) ]]; then
            has_exit=true
            break
        fi
    done

    if [[ "$has_exit" == false ]]; then
        options+=("🔙 Back/Exit")
    fi

    local choice
    choice=$(gum_menu_styled "$title" "${options[@]}")
    local exit_code=$?

    # If user cancelled or selected Back/Exit
    if [[ $exit_code -ne 0 ]] || [[ "$choice" == *"Back/Exit"* ]]; then
        return 1
    fi

    echo "$choice"
    return 0
}

gum_input() {
    local prompt="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        gum_input_with_default "$prompt" "$default"
    else
        gum_input_required "$prompt" "Enter value..."
    fi
}

# Enhanced WP-CLI command runner with better error handling
run_wp_cli_command() {
    local cmd="$1"
    local success_msg="$2"
    local show_output="${3:-true}"

    if [[ "$show_output" == "true" ]]; then
        log_info "Executing: wp $cmd"
        if docker exec ${WP_CLI_CONTAINER} wp $cmd; then
            if [[ -n "$success_msg" ]]; then
                log_success "$success_msg"
            fi
            return 0
        else
            log_error "Command failed: wp $cmd"
            return 1
        fi
    else
        # Silent execution with spinner
        if run_with_spinner "Executing WP-CLI command..." "docker exec ${WP_CLI_CONTAINER} wp $cmd"; then
            if [[ -n "$success_msg" ]]; then
                log_success "$success_msg"
            fi
            return 0
        else
            log_error "Command failed: wp $cmd"
            return 1
        fi
    fi
}

# Refactored function to handle both plugin and vite mappings
generate_mappings() {
    local mappings=""
    local -n array_ref=$1

    # Check if array is empty
    if [[ ${#array_ref[@]} -gt 0 ]]; then
        for item in "${array_ref[@]}"; do
            mappings+="      - $item\n"
        done
    fi
    echo -e "$mappings"
}

# Update calls to use the refactored function
get_plugin_mappings() {
    generate_mappings WP_PLUGIN_PATHS
}

get_vite_plugin_mappings() {
    generate_mappings VITE_PLUGIN_PATHS
}

# Ensure WP_PLUGIN_PATHS is properly initialized and formatted
if [[ -z "${WP_PLUGIN_PATHS[*]}" ]]; then
    log_info "Loading wp plugin paths from configuration file..."
    eval "WP_PLUGIN_PATHS=($WP_PLUGIN_PATHS)"
fi

# Load vite plugin paths from configuration file
if [[ -n "$VITE_PLUGIN_PATHS" ]]; then
    log_info "Loading vite plugin paths from configuration file..."
    eval "VITE_PLUGIN_PATHS=($VITE_PLUGIN_PATHS)"
fi

# Save configuration to file
save_config() {
    log_info "Saving configuration to $CONFIG_FILE..."

    cat >"$CONFIG_FILE" <<EOF
# WordPress Docker Environment Configuration
# Generated on $(date)

# Project settings
PROJECT_NAME="$PROJECT_NAME"
DOMAIN="$DOMAIN"
VITE_DEV_SERVER="$VITE_DEV_SERVER"

# Docker images
DB_IMAGE="$DB_IMAGE"
WP_IMAGE="$WP_IMAGE"
WP_UNIT_TESTING_IMAGE="$WP_UNIT_TESTING_IMAGE"
NGINX_IMAGE="$NGINX_IMAGE"
APACHE_WP_IMAGE="$APACHE_WP_IMAGE"
NODE_IMAGE="$NODE_IMAGE"
REDIS_IMAGE="$REDIS_IMAGE"
VITE_IMAGE="$VITE_IMAGE"

# Directory paths
DATA_DIR="$DATA_DIR"
CONFIG_DIR="$CONFIG_DIR"
DOCKER_DIR="$DOCKER_DIR"

# Database settings
MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
MYSQL_DATABASE="$MYSQL_DATABASE"
MYSQL_USER="$MYSQL_USER"
MYSQL_PASSWORD="$MYSQL_PASSWORD"

# WordPress settings
WP_TABLE_PREFIX="$WP_TABLE_PREFIX"
WP_DEBUG="$WP_DEBUG"
WP_DEBUG_DISPLAY="$WP_DEBUG_DISPLAY"
WP_DEBUG_LOG="$WP_DEBUG_LOG"
WP_SAVEQUERIES="$WP_SAVEQUERIES"
WP_SCRIPT_DEBUG="$WP_SCRIPT_DEBUG"

# Docker networks
DOCKER_DEV_NETWORK="$DOCKER_DEV_NETWORK"
DOCKER_PROD_NETWORK="$DOCKER_PROD_NETWORK"

# Container names
WP_CONTAINER="$WP_CONTAINER"
DB_CONTAINER="$DB_CONTAINER"
WP_CLI_CONTAINER="$WP_CLI_CONTAINER"
REDIS_CONTAINER="$REDIS_CONTAINER"
NGINX_CONTAINER="$NGINX_CONTAINER"
VITE_CONTAINER="$VITE_CONTAINER"

# User settings
USER_ID="$USER_ID"
GROUP_ID="$GROUP_ID"

# Remote sync configuration
REMOTE_SSH_HOST="$REMOTE_SSH_HOST"
REMOTE_PROJECT_PATH="$REMOTE_PROJECT_PATH"
REMOTE_DB_CONTAINER="$REMOTE_DB_CONTAINER"
REMOTE_DB_USER="$REMOTE_DB_USER"
REMOTE_DB_PASSWORD="$REMOTE_DB_PASSWORD"
REMOTE_DB_NAME="$REMOTE_DB_NAME"
LOCAL_DOMAIN="$LOCAL_DOMAIN"
REMOTE_DOMAIN="$REMOTE_DOMAIN"

# Proxy container settings
PROXY_CONTAINER_NAME="$PROXY_CONTAINER_NAME"
PROXY_NETWORK="$PROXY_NETWORK"
PROXY_CERTS_DIR="$PROXY_CERTS_DIR"
PROXY_IMAGE="$PROXY_IMAGE"
PROXY_CERT_FILE="$PROXY_CERT_FILE"
PROXY_KEY_FILE="$PROXY_KEY_FILE"
EOF

    log_success "Configuration saved successfully!"
}

# Configure project settings menu
configure_project() {
    while true; do
        local options=(
            "1️⃣  Project name: $PROJECT_NAME"
            "2️⃣  Domain: $DOMAIN"
            "3️⃣  Vite dev server: $VITE_DEV_SERVER"
            "4️⃣  MySQL database: $MYSQL_DATABASE"
            "5️⃣  MySQL user: $MYSQL_USER"
            "6️⃣  MySQL password: $MYSQL_PASSWORD"
            "7️⃣  MySQL root password: $MYSQL_ROOT_PASSWORD"
            "8️⃣  Docker dev network: $DOCKER_DEV_NETWORK"
            "💾  Save configuration and return"
        )

        local choice
        choice=$(gum_menu "Project Configuration" "${options[@]}")

        # Exit if user selected back/exit (return code 1)
        if [[ $? -ne 0 ]]; then
            return 0
        fi

        case "$choice" in
        *"Project name:"*)
            local new_project_name
            new_project_name=$(gum_input "Enter project name" "$PROJECT_NAME")
            if [[ -n "$new_project_name" ]]; then
                PROJECT_NAME="$new_project_name"
                log_success "Project name updated to: $PROJECT_NAME"
                # Update container names based on project name if they are default
                if [[ "$WP_CONTAINER" == "wordpress" ]]; then
                    WP_CONTAINER="${PROJECT_NAME}_wp"
                fi
                if [[ "$DB_CONTAINER" == "db" ]]; then
                    DB_CONTAINER="${PROJECT_NAME}_db"
                fi
                if [[ "$WP_CLI_CONTAINER" == "wp-cli" ]]; then
                    WP_CLI_CONTAINER="${PROJECT_NAME}_wpcli"
                fi
                if [[ "$REDIS_CONTAINER" == "redis" ]]; then
                    REDIS_CONTAINER="${PROJECT_NAME}_redis"
                fi
                if [[ "$NGINX_CONTAINER" == "nginx" ]]; then
                    NGINX_CONTAINER="${PROJECT_NAME}_nginx"
                fi
                if [[ "$VITE_CONTAINER" == "vite" ]]; then
                    VITE_CONTAINER="${PROJECT_NAME}_vite"
                fi
            fi
            ;;
        *"Domain:"*)
            local new_domain
            new_domain=$(gum_input "Enter domain" "$DOMAIN")
            if [[ -n "$new_domain" ]]; then
                DOMAIN="$new_domain"
                log_success "Domain updated to: $DOMAIN"
                # Update local domain if it matches the default
                if [[ "$LOCAL_DOMAIN" == "example.local" ]]; then
                    LOCAL_DOMAIN="$DOMAIN"
                fi
            fi
            ;;
        *"Vite dev server:"*)
            local new_vite_dev_server
            new_vite_dev_server=$(gum_input "Enter Vite dev server domain" "$VITE_DEV_SERVER")
            if [[ -n "$new_vite_dev_server" ]]; then
                VITE_DEV_SERVER="$new_vite_dev_server"
                log_success "Vite dev server updated to: $VITE_DEV_SERVER"
            fi
            ;;
        *"MySQL database:"*)
            local new_mysql_database
            new_mysql_database=$(gum_input "Enter MySQL database name" "$MYSQL_DATABASE")
            if [[ -n "$new_mysql_database" ]]; then
                MYSQL_DATABASE="$new_mysql_database"
                log_success "MySQL database updated to: $MYSQL_DATABASE"
            fi
            ;;
        *"MySQL user:"*)
            local new_mysql_user
            new_mysql_user=$(gum_input "Enter MySQL user" "$MYSQL_USER")
            if [[ -n "$new_mysql_user" ]]; then
                MYSQL_USER="$new_mysql_user"
                log_success "MySQL user updated to: $MYSQL_USER"
            fi
            ;;
        *"MySQL password:"*)
            local new_mysql_password
            new_mysql_password=$(gum_input "Enter MySQL password" "$MYSQL_PASSWORD")
            if [[ -n "$new_mysql_password" ]]; then
                MYSQL_PASSWORD="$new_mysql_password"
                log_success "MySQL password updated"
            fi
            ;;
        *"MySQL root password:"*)
            local new_mysql_root_password
            new_mysql_root_password=$(gum_input "Enter MySQL root password" "$MYSQL_ROOT_PASSWORD")
            if [[ -n "$new_mysql_root_password" ]]; then
                MYSQL_ROOT_PASSWORD="$new_mysql_root_password"
                log_success "MySQL root password updated"
            fi
            ;;
        *"Docker dev network:"*)
            local new_docker_dev_network
            new_docker_dev_network=$(gum_input "Enter Docker dev network name" "$DOCKER_DEV_NETWORK")
            if [[ -n "$new_docker_dev_network" ]]; then
                DOCKER_DEV_NETWORK="$new_docker_dev_network"
                log_success "Docker dev network updated to: $DOCKER_DEV_NETWORK"
            fi
            ;;
        *"Save configuration"*)
            save_config
            log_success "Configuration saved!"
            return 0
            ;;
        esac
    done
}

# Configure advanced settings menu
configure_advanced() {
    while true; do
        local options=(
            "🐘  WordPress production image: $WP_IMAGE"
            "🛠️  WordPress dev image: $WP_UNIT_TESTING_IMAGE"
            "🗄️  DB image: $DB_IMAGE"
            "🌐  Nginx image: $NGINX_IMAGE"
            "🔥  Apache WordPress image: $APACHE_WP_IMAGE"
            "⚡  Vite image: $VITE_IMAGE"
            "🚀  Redis image: $REDIS_IMAGE"
            "📁  Data directory: $DATA_DIR"
            "⚙️  Config directory: $CONFIG_DIR"
            "🐳  Docker directory: $DOCKER_DIR"
            "🏷️  WordPress table prefix: $WP_TABLE_PREFIX"
            "🐛  WordPress debug: $WP_DEBUG"
            "🌍  Production Docker network: $DOCKER_PROD_NETWORK"
            "💾  Save configuration and return"
        )

        local choice
        choice=$(gum_menu "Advanced Configuration" "${options[@]}")

        # Exit if user selected back/exit
        if [[ $? -ne 0 ]]; then
            return 0
        fi

        case "$choice" in
        *"WordPress production image:"*)
            local new_wp_image
            new_wp_image=$(gum_input "Enter WordPress production image" "$WP_IMAGE")
            if [[ -n "$new_wp_image" ]]; then
                WP_IMAGE="$new_wp_image"
                log_success "WordPress production image updated to: $WP_IMAGE"
            fi
            ;;
        *"WordPress dev image:"*)
            local new_wp_unit_testing_image
            new_wp_unit_testing_image=$(gum_input "Enter WordPress dev image" "$WP_UNIT_TESTING_IMAGE")
            if [[ -n "$new_wp_unit_testing_image" ]]; then
                WP_UNIT_TESTING_IMAGE="$new_wp_unit_testing_image"
                log_success "WordPress dev image updated to: $WP_UNIT_TESTING_IMAGE"
            fi
            ;;
        *"DB image:"*)
            local new_db_image
            new_db_image=$(gum_input "Enter DB image" "$DB_IMAGE")
            if [[ -n "$new_db_image" ]]; then
                DB_IMAGE="$new_db_image"
                log_success "DB image updated to: $DB_IMAGE"
            fi
            ;;
        *"Nginx image:"*)
            local new_nginx_image
            new_nginx_image=$(gum_input "Enter Nginx image" "$NGINX_IMAGE")
            if [[ -n "$new_nginx_image" ]]; then
                NGINX_IMAGE="$new_nginx_image"
                log_success "Nginx image updated to: $NGINX_IMAGE"
            fi
            ;;
        *"Apache WordPress image:"*)
            local new_apache_wp_image
            new_apache_wp_image=$(gum_input "Enter Apache WordPress image" "$APACHE_WP_IMAGE")
            if [[ -n "$new_apache_wp_image" ]]; then
                APACHE_WP_IMAGE="$new_apache_wp_image"
                log_success "Apache WordPress image updated to: $APACHE_WP_IMAGE"
            fi
            ;;
        *"Vite image:"*)
            local new_vite_image
            new_vite_image=$(gum_input "Enter Vite image" "$VITE_IMAGE")
            if [[ -n "$new_vite_image" ]]; then
                VITE_IMAGE="$new_vite_image"
                log_success "Vite image version updated to $VITE_IMAGE"
            fi
            ;;
        *"Redis image:"*)
            local new_redis_image
            new_redis_image=$(gum_input "Enter Redis image" "$REDIS_IMAGE")
            if [[ -n "$new_redis_image" ]]; then
                REDIS_IMAGE="$new_redis_image"
                log_success "Redis image updated to: $REDIS_IMAGE"
            fi
            ;;
        *"Data directory:"*)
            local new_data_dir
            new_data_dir=$(gum_input "Enter data directory path" "$DATA_DIR")
            if [[ -n "$new_data_dir" ]]; then
                DATA_DIR="$new_data_dir"
                log_success "Data directory updated to: $DATA_DIR"
            fi
            ;;
        *"Config directory:"*)
            local new_config_dir
            new_config_dir=$(gum_input "Enter config directory path" "$CONFIG_DIR")
            if [[ -n "$new_config_dir" ]]; then
                CONFIG_DIR="$new_config_dir"
                log_success "Config directory updated to: $CONFIG_DIR"
            fi
            ;;
        *"Docker directory:"*)
            local new_docker_dir
            new_docker_dir=$(gum_input "Enter docker directory path" "$DOCKER_DIR")
            if [[ -n "$new_docker_dir" ]]; then
                DOCKER_DIR="$new_docker_dir"
                log_success "Docker directory updated to: $DOCKER_DIR"
            fi
            ;;
        *"WordPress table prefix:"*)
            local new_wp_table_prefix
            new_wp_table_prefix=$(gum_input "Enter WordPress table prefix" "$WP_TABLE_PREFIX")
            if [[ -n "$new_wp_table_prefix" ]]; then
                WP_TABLE_PREFIX="$new_wp_table_prefix"
                log_success "WordPress table prefix updated to: $WP_TABLE_PREFIX"
            fi
            ;;
        *"WordPress debug:"*)
            local debug_options=("true" "false")
            local new_wp_debug
            new_wp_debug=$(gum_menu "Select WordPress debug mode" "${debug_options[@]}")
            if [[ -n "$new_wp_debug" ]]; then
                WP_DEBUG="$new_wp_debug"
                log_success "WordPress debug updated to: $WP_DEBUG"
            fi
            ;;
        *"Production Docker network:"*)
            local new_docker_prod_network
            new_docker_prod_network=$(gum_input "Enter production Docker network" "$DOCKER_PROD_NETWORK")
            if [[ -n "$new_docker_prod_network" ]]; then
                DOCKER_PROD_NETWORK="$new_docker_prod_network"
                log_success "Production Docker network updated to: $DOCKER_PROD_NETWORK"
            fi
            ;;
        *"Save configuration"*)
            save_config
            log_success "Configuration saved!"
            return 0
            ;;
        esac
    done
}

# Configure remote server settings menu
configure_remote_server() {
    while true; do
        # Display SSH config info
        echo
        gum style --foreground="$THEME_INFO" "ℹ INFO: SSH connection details are read from ~/.ssh/config"
        gum style --foreground="$THEME_MUTED" "Configure your SSH host alias, user, and keys in ~/.ssh/config"
        echo

        local options=(
            "🌐  SSH Host alias: $REMOTE_SSH_HOST"
            "📁  Remote project path: $REMOTE_PROJECT_PATH"
            "🗄️  Remote DB container: $REMOTE_DB_CONTAINER"
            "👤  Remote DB user: $REMOTE_DB_USER"
            "🔑  Remote DB password: $REMOTE_DB_PASSWORD"
            "🗃️  Remote DB name: $REMOTE_DB_NAME"
            "💾  Save configuration and return"
        )

        local choice
        choice=$(gum_menu "Remote Server Configuration" "${options[@]}")

        # Exit if user selected back/exit
        if [[ $? -ne 0 ]]; then
            return 0
        fi

        case "$choice" in
        *"SSH Host:"*)
            local new_ssh_host
            new_ssh_host=$(gum_input "Enter remote SSH host (IP or hostname)" "$REMOTE_SSH_HOST")
            if [[ -n "$new_ssh_host" ]]; then
                REMOTE_SSH_HOST="$new_ssh_host"
                log_success "Remote SSH host updated to: $REMOTE_SSH_HOST"
            fi
            ;;
        *"Remote project path:"*)
            local new_project_path
            new_project_path=$(gum_input "Enter remote project path" "$REMOTE_PROJECT_PATH")
            if [[ -n "$new_project_path" ]]; then
                REMOTE_PROJECT_PATH="$new_project_path"
                log_success "Remote project path updated to: $REMOTE_PROJECT_PATH"
            fi
            ;;
        *"Remote DB container:"*)
            local new_db_container
            new_db_container=$(gum_input "Enter remote database container name" "$REMOTE_DB_CONTAINER")
            if [[ -n "$new_db_container" ]]; then
                REMOTE_DB_CONTAINER="$new_db_container"
                log_success "Remote DB container updated to: $REMOTE_DB_CONTAINER"
            fi
            ;;
        *"Remote DB user:"*)
            local new_db_user
            new_db_user=$(gum_input "Enter remote database user" "$REMOTE_DB_USER")
            if [[ -n "$new_db_user" ]]; then
                REMOTE_DB_USER="$new_db_user"
                log_success "Remote DB user updated to: $REMOTE_DB_USER"
            fi
            ;;
        *"Remote DB password:"*)
            local new_db_password
            new_db_password=$(gum_input "Enter remote database password" "$REMOTE_DB_PASSWORD")
            if [[ -n "$new_db_password" ]]; then
                REMOTE_DB_PASSWORD="$new_db_password"
                log_success "Remote DB password updated"
            fi
            ;;
        *"Remote DB name:"*)
            local new_db_name
            new_db_name=$(gum_input "Enter remote database name" "$REMOTE_DB_NAME")
            if [[ -n "$new_db_name" ]]; then
                REMOTE_DB_NAME="$new_db_name"
                log_success "Remote DB name updated to: $REMOTE_DB_NAME"
            fi
            ;;
        *"Save configuration"*)
            save_config
            log_success "Configuration saved!"
            return 0
            ;;
        esac
    done
}

# Manage hosts file submenu
manage_hosts_file() {
    while true; do
        local options=(
            "➕  Add domain to hosts file"
            "➖  Remove domain from hosts file"
            "🔍  Check if domain exists in hosts file"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Manage Hosts File" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Add domain"*)
            if grep -q "$DOMAIN" /etc/hosts; then
                log_warning "Domain $DOMAIN already exists in the hosts file."
            else
                echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
                log_success "Domain $DOMAIN added to hosts file."
            fi
            ;;
        *"Remove domain"*)
            if grep -q "$DOMAIN" /etc/hosts; then
                sudo sed -i "/$DOMAIN/d" /etc/hosts
                log_success "Domain $DOMAIN removed from hosts file."
            else
                log_warning "Domain $DOMAIN not found in the hosts file."
            fi
            ;;
        *"Check if domain"*)
            if grep -q "$DOMAIN" /etc/hosts; then
                log_info "Domain $DOMAIN exists in the hosts file."
            else
                log_info "Domain $DOMAIN does not exist in the hosts file."
            fi
            ;;
        esac
    done
}

# Manage proxy container submenu
manage_proxy_container() {
    while true; do
        local options=(
            "🚀  Run main proxy container"
            "🛑  Stop and remove proxy container"
            "📊  Check proxy container status"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Manage Proxy Container" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Run main proxy container"*)
            # Check if ports 80 and 443 are free
            if lsof -i:80 -i:443 &>/dev/null; then
                log_error "Ports 80 and/or 443 are already in use. Please stop any services using these ports and try again."
                continue
            fi

            # Check if the Docker image exists, pull if not
            if ! docker image inspect "$PROXY_IMAGE" &>/dev/null; then
                log_info "Docker image $PROXY_IMAGE not found. Pulling the image..."
                docker pull "$PROXY_IMAGE"
                log_success "Docker image $PROXY_IMAGE pulled successfully."
            fi

            # Check if container already exists
            if docker ps --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_info "Proxy container $PROXY_CONTAINER_NAME is already running."
                continue
            elif docker ps -a --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_info "Container exists but is not running. Starting container..."
                docker start "$PROXY_CONTAINER_NAME"
                log_success "Proxy container $PROXY_CONTAINER_NAME started."
                continue
            fi

            # Run the proxy container
            log_info "Running the proxy container..."
            docker run --name "$PROXY_CONTAINER_NAME" --net "$PROXY_NETWORK" -d --restart=unless-stopped \
                -p 80:80 -p 443:443 \
                -v /var/run/docker.sock:/tmp/docker.sock:ro \
                -v "$PROXY_CERTS_DIR:/etc/nginx/certs" \
                "$PROXY_IMAGE"

            log_success "Proxy container $PROXY_CONTAINER_NAME is now running."
            ;;
        *"Stop and remove proxy container"*)
            # Stop and remove the proxy container
            if docker ps -a --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_info "Stopping and removing the proxy container..."
                docker stop "$PROXY_CONTAINER_NAME" && docker rm "$PROXY_CONTAINER_NAME"
                log_success "Proxy container $PROXY_CONTAINER_NAME stopped and removed."
            else
                log_warning "Proxy container $PROXY_CONTAINER_NAME is not running."
            fi
            ;;
        *"Check proxy container status"*)
            # Check the status of the proxy container
            if docker ps --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_success "Proxy container $PROXY_CONTAINER_NAME is running."
            else
                log_info "Proxy container $PROXY_CONTAINER_NAME is not running."
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Docker management submenu
configure_docker_menu() {
    while true; do
        local options=(
            "🔨  Build and start containers"
            "⏹️  Stop containers"
            "▶️  Start containers"
            "🔄  Restart containers"
            "🗑️  Remove containers"
            "📋  View logs"
            "🐚  Access container shell"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Docker Management Menu" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Build and start containers"*)
            handleDocker "build"
            ;;
        *"Stop containers"*)
            handleDocker "stop"
            ;;
        *"Start containers"*)
            handleDocker "start"
            ;;
        *"Restart containers"*)
            handleDocker "restart"
            ;;
        *"Remove containers"*)
            handleDocker "remove"
            ;;
        *"View logs"*)
            local container
            container=$(gum_input "Enter container name (wp, db, nginx, redis, vite)" "")
            if [[ -n "$container" ]]; then
                handleDocker "logs" "$container"
            fi
            ;;
        *"Access container shell"*)
            local container
            container=$(gum_input "Enter container name (wp, db, nginx, redis, vite, wpcli)" "")
            if [[ -n "$container" ]]; then
                handleDocker "shell" "$container"
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# WP-CLI submenu
configure_wpcli_menu() {
    while true; do
        local options=(
            "🚀  Install WordPress"
            "👤  Create user"
            "🔌  Install plugin"
            "🎨  Install theme"
            "🐛  Enable debugging"
            "🔇  Disable debugging"
            "⚙️  Run custom WP-CLI command"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "WP-CLI Management Menu" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Install WordPress"*)
            handleWpCli "install"
            ;;
        *"Create user"*)
            local username email role password

            username=$(gum_input "Enter username" "")
            if [[ -z "$username" ]]; then continue; fi

            email=$(gum_input "Enter email" "")
            if [[ -z "$email" ]]; then continue; fi

            role=$(gum_input "Enter role" "subscriber")
            if [[ -z "$role" ]]; then role="subscriber"; fi

            # For password, we'll use read with hidden input since gum doesn't support password fields
            echo -n "Enter password: "
            read -s password
            echo
            if [[ -z "$password" ]]; then password="password"; fi

            handleWpCli "create-user" "$username" "$email" "$role" "$password"
            ;;
        *"Install plugin"*)
            local plugin
            plugin=$(gum_input "Enter plugin name" "")
            if [[ -n "$plugin" ]]; then
                handleWpCli "install-plugin" "$plugin"
            fi
            ;;
        *"Install theme"*)
            local theme
            theme=$(gum_input "Enter theme name" "")
            if [[ -n "$theme" ]]; then
                handleWpCli "install-theme" "$theme"
            fi
            ;;
        *"Enable debugging"*)
            handleWpCli "debug-on"
            ;;
        *"Disable debugging"*)
            handleWpCli "debug-off"
            ;;
        *"Run custom WP-CLI command"*)
            local custom_cmd
            custom_cmd=$(gum_input "Enter custom WP-CLI command" "")
            if [[ -n "$custom_cmd" ]]; then
                handleWpCli "custom" "$custom_cmd"
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Manage Docker images submenu
manage_docker_images_menu() {
    while true; do
        local options=(
            "🔨  Build development image (Current: $WP_UNIT_TESTING_IMAGE)"
            "🏭  Build production image (Current: $WP_IMAGE)"
            "⚡  Build Vite image (Current: $VITE_IMAGE)"
            "✏️  Edit image versions"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Manage Docker Images" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Build development image"*)
            log_info "Building development image: $WP_UNIT_TESTING_IMAGE..."
            docker build -f .docker/wp/Dockerfile.dev -t $WP_UNIT_TESTING_IMAGE .
            log_success "Development image built successfully!"
            ;;
        *"Build production image"*)
            log_info "Building production image: $WP_IMAGE..."
            docker build -f .docker/wp/Dockerfile.prod -t $WP_IMAGE .
            log_success "Production image built successfully!"
            ;;
        *"Build Vite image"*)
            log_info "Building Vite image: $VITE_IMAGE..."
            docker build -f .docker/vite/Dockerfile.prod -t $VITE_IMAGE .
            log_success "Vite image built and tagged as $VITE_IMAGE!"
            ;;
        *"Edit image versions"*)
            local new_dev_image new_prod_image new_vite_image

            new_dev_image=$(gum_input "Enter new development image version (Current: $WP_UNIT_TESTING_IMAGE)" "$WP_UNIT_TESTING_IMAGE")
            if [[ -n "$new_dev_image" ]]; then
                WP_UNIT_TESTING_IMAGE="$new_dev_image"
                log_success "Development image version updated to $WP_UNIT_TESTING_IMAGE"
            fi

            new_prod_image=$(gum_input "Enter new production image version (Current: $WP_IMAGE)" "$WP_IMAGE")
            if [[ -n "$new_prod_image" ]]; then
                WP_IMAGE="$new_prod_image"
                log_success "Production image version updated to $WP_IMAGE"
            fi

            new_vite_image=$(gum_input "Enter new Vite image version (Current: $VITE_IMAGE)" "$VITE_IMAGE")
            if [[ -n "$new_vite_image" ]]; then
                VITE_IMAGE="$new_vite_image"
                log_success "Vite image version updated to $VITE_IMAGE"
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Enhanced requirements check with visual feedback and version info
check_requirements() {
    section_header "🔍 System Requirements Check"

    # Define required tools with their minimum versions
    declare -A required_tools=(
        ["docker"]="20.10.0"
        ["curl"]="7.0.0"
        ["gum"]="0.8.0"
    )

    local all_good=true
    local check_results=()

    # Check each required tool
    for tool in "${!required_tools[@]}"; do
        local min_version="${required_tools[$tool]}"

        if command -v "$tool" &>/dev/null; then
            local current_version=""
            case "$tool" in
            "docker")
                current_version=$(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
                ;;
            "curl")
                current_version=$(curl --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
                ;;
            "gum")
                current_version=$(gum --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
                ;;
            esac

            if [[ -n "$current_version" ]]; then
                check_results+=("✅ $tool: $current_version (min: $min_version)")
            else
                check_results+=("✅ $tool: installed (version check failed)")
            fi
        else
            check_results+=("❌ $tool: NOT FOUND (required: $min_version)")
            all_good=false
        fi
    done

    # Check Docker Compose separately
    if docker compose version &>/dev/null; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        check_results+=("✅ docker compose: $compose_version")
    else
        check_results+=("❌ docker compose: NOT FOUND")
        all_good=false
    fi

    # Check optional but recommended tools
    local optional_tools=("mkcert" "git")
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            case "$tool" in
            "mkcert")
                local version=$(mkcert -version 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -1 || echo "unknown")
                check_results+=("🔧 $tool: $version (optional - for SSL certificates)")
                ;;
            "git")
                local version=$(git --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
                check_results+=("🔧 git: $version (optional - for version control)")
                ;;
            esac
        else
            check_results+=("⚠️  $tool: not found (optional)")
        fi
    done

    # Display results with proper formatting
    echo
    gum style --foreground="$THEME_INFO" --bold "System Check Results:"
    echo

    for result in "${check_results[@]}"; do
        echo "  $result"
    done

    echo

    # Show system information
    gum style --foreground="$THEME_MUTED" "System Information:"
    echo "  🖥️  OS: $(uname -s)"
    echo "  🏗️  Architecture: $(uname -m)"
    echo "  👤 User: $(whoami) (UID: $(id -u), GID: $(id -g))"

    # Check if running as root (which we don't want)
    if [[ $EUID -eq 0 ]]; then
        echo
        log_error "Script is running as root! This is not recommended for security reasons."
        gum_confirm_styled "Continue anyway?" false || exit 1
    fi

    echo

    if [[ "$all_good" == true ]]; then
        log_success "All required tools are available! 🎉"

        # Check Docker daemon
        if ! docker info &>/dev/null; then
            log_warning "Docker daemon is not running. Please start Docker and try again."
            return 1
        else
            log_success "Docker daemon is running properly."
        fi

        # Check available disk space
        local available_space=$(df . | awk 'NR==2 {print $4}')
        local space_gb=$((available_space / 1024 / 1024))

        if [[ $space_gb -lt 2 ]]; then
            log_warning "Low disk space: ${space_gb}GB available. WordPress environment needs at least 2GB."
        else
            log_success "Sufficient disk space: ${space_gb}GB available."
        fi

    else
        echo
        log_error "Some required tools are missing!"
        echo
        gum style --foreground="$THEME_WARNING" "📋 Installation Instructions:"
        echo
        echo "  Docker: https://docs.docker.com/get-docker/"
        echo "  Gum: https://github.com/charmbracelet/gum#installation"
        echo "  curl: Usually pre-installed, or via package manager"
        echo "  mkcert (optional): https://github.com/FiloSottile/mkcert#installation"
        echo

        if ! gum_confirm_styled "Continue anyway? (some features may not work)" false; then
            exit 1
        fi
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."

    mkdir -p "${DATA_DIR}/mysql" "${DATA_DIR}/site" "${DATA_DIR}/redis"
    mkdir -p "${CONFIG_DIR}/nginx" "${CONFIG_DIR}/nginx/includes" "${CONFIG_DIR}/php"

    log_success "Directories created!"
}

# Generate certificates using mkcert
generate_certs() {
    log_info "Checking if mkcert is installed..."
    if ! command -v mkcert &>/dev/null; then
        log_error "mkcert is not installed. Please install mkcert and try again."
        return
    fi

    # Set default proxy certs directory to user's home directory appended with 'certs'
    local default_proxy_certs_dir="$HOME/certs"

    # Prompt user to set proxy certs directory
    local new_proxy_certs_dir
    new_proxy_certs_dir=$(gum_input "Enter the directory to save proxy certificates" "$default_proxy_certs_dir")
    if [[ -n "$new_proxy_certs_dir" ]]; then
        PROXY_CERTS_DIR="$new_proxy_certs_dir"
    else
        PROXY_CERTS_DIR="$default_proxy_certs_dir"
    fi

    log_info "Generating certificates using mkcert..."
    mkdir -p "$PROXY_CERTS_DIR"
    sh -c "mkcert -cert-file \"$PROXY_CERTS_DIR/$PROXY_CERT_FILE\" -key-file \"$PROXY_CERTS_DIR/$PROXY_KEY_FILE\" \"$DOMAIN\" \"*.$DOMAIN\""

    if [[ -f "$PROXY_CERTS_DIR/$PROXY_CERT_FILE" && -f "$PROXY_CERTS_DIR/$PROXY_KEY_FILE" ]]; then
        log_success "Certificates generated successfully and saved to $PROXY_CERTS_DIR."
    else
        log_error "Failed to generate certificates. Please check mkcert installation and permissions."
    fi
}

# Generate configuration files
generate_configs() {
    local config_type=$1
    log_info "Generating $config_type configurations..."

    case "$config_type" in
    "env")
        cat <<EOF >.env
# Compose project name
COMPOSE_PROJECT_NAME=$PROJECT_NAME
PROJECT_NAME=$PROJECT_NAME
DOMAIN=$DOMAIN
VITE_DEV_SERVER=$VITE_DEV_SERVER
DB_IMAGE=$DB_IMAGE
WP_UNIT_TESTING_IMAGE=$WP_UNIT_TESTING_IMAGE
APACHE_WP_IMAGE=$APACHE_WP_IMAGE
DATA_DIR=$DATA_DIR
CONFIG_DIR=$CONFIG_DIR
DOCKER_DIR=$DOCKER_DIR
DB_FILES=$DATA_DIR/mysql
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
SITE_FILES=$DATA_DIR/site
LOGGING_OPTIONS_MAX_SIZE=200k
WP_TABLE_PREFIX=$WP_TABLE_PREFIX
WP_DEBUG=$WP_DEBUG
WP_DEBUG_DISPLAY=$WP_DEBUG_DISPLAY
WP_DEBUG_LOG=$WP_DEBUG_LOG
WP_REDIS_HOST=$REDIS_CONTAINER
WORDPRESS_DB_NAME=$MYSQL_DATABASE
WORDPRESS_DB_USER=$MYSQL_USER
WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
WORDPRESS_DB_HOST=$DB_CONTAINER
WORDPRESS_TABLE_PREFIX=$WP_TABLE_PREFIX
WORDPRESS_DEBUG=$WP_DEBUG
WORDPRESS_DEBUG_LOG=$WP_DEBUG_LOG
WORDPRESS_DEBUG_DISPLAY=$WP_DEBUG_DISPLAY
WORDPRESS_REDIS_HOST=$REDIS_CONTAINER
WORDPRESS_SAVEQUERIES=$WP_SAVEQUERIES
WORDPRESS_SCRIPT_DEBUG=$WP_SCRIPT_DEBUG
WP_CONTAINER=$WP_CONTAINER
DB_CONTAINER=$DB_CONTAINER
WP_CLI_CONTAINER=$WP_CLI_CONTAINER
REDIS_CONTAINER=$REDIS_CONTAINER
NGINX_CONTAINER=$NGINX_CONTAINER
VITE_CONTAINER=$VITE_CONTAINER
PHP_INI=$CONFIG_DIR/php/php.ini
NGINX_CONFIG=$CONFIG_DIR/nginx/nginx.conf
USER_ID=$USER_ID
GROUP_ID=$GROUP_ID
PROXY_CONTAINER_NAME=$PROXY_CONTAINER_NAME
PROXY_NETWORK=$PROXY_NETWORK
PROXY_CERTS_DIR=$PROXY_CERTS_DIR
PROXY_IMAGE=$PROXY_IMAGE
PROXY_CERT_FILE=$PROXY_CERT_FILE
PROXY_KEY_FILE=$PROXY_KEY_FILE
EOF
        ;;

    "php")
        mkdir -p "${CONFIG_DIR}/php"

        # xdebug config
        cat <<EOF >$CONFIG_DIR/php/xdebug.ini
[xdebug]
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.client_port=9003
xdebug.client_host=host.docker.internal
xdebug.start_with_request=yes
xdebug.log=/var/log/xdebug/xdebug.log
xdebug.discover_client_host=true
xdebug.max_nesting_level=512
xdebug.idekey="VSCODE"
EOF

        # php.ini
        cat <<EOF >$CONFIG_DIR/php/php.ini
[PHP]
file_uploads = On
upload_max_filesize = 256M
memory_limit = 1024M
post_max_size = 256M
max_execution_time = 600
expose_php = Off
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log

[Date]
date.timezone = "UTC"

[opcache]
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 30000
opcache.revalidate_freq = 0
opcache.validate_timestamps = 1
opcache.save_comments = 1
opcache.jit_buffer_size=128M
opcache.jit=tracing
EOF

        # Development php.ini
        cat <<EOF >$CONFIG_DIR/php/php-development.ini
; Development-specific PHP settings
display_errors = On
error_reporting = E_ALL
log_errors = On
memory_limit = 1536M
max_execution_time = 1200
max_input_time = 1200
EOF
        ;;

    "nginx")
        mkdir -p "${CONFIG_DIR}/nginx" "${CONFIG_DIR}/nginx/includes"

        # Main nginx config
        cat <<EOF >$CONFIG_DIR/nginx/nginx-main.conf
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    root /var/www/html;
    index index.php;
    
    server_tokens off;
    include /etc/nginx/conf.d/includes/*.conf;
    
    client_max_body_size 100M;
    
    # Gzip Settings
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
          text/plain
          text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # Static files caching - Enhanced
    location ~* \.(jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot|webp|avif|mp4|webm|pdf|zip)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public, immutable, max-age=31536000";
        add_header Vary "Accept-Encoding";
        try_files \$uri =404;
    }

    # Separate shorter cache for CSS/JS that might change more often
    location ~* \.(css|js)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public, max-age=2592000";
        add_header Vary "Accept-Encoding";
        try_files \$uri =404;
    }
    
    # WordPress admin and login pages - no cache
    location ~* ^/(wp-admin|wp-login\.php) {
        try_files \$uri \$uri/ /index.php?\$args;
        
        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass ${WP_CONTAINER}:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
            fastcgi_read_timeout 300;
            
            # No caching for admin
            fastcgi_cache_bypass 1;
            fastcgi_no_cache 1;
        }
    }
    
    # Pass PHP scripts to FastCGI server with caching
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass ${WP_CONTAINER}:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_read_timeout 300;
        
        # FastCGI Cache Settings
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 301 302 30m;
        fastcgi_cache_valid 404 1m;
        fastcgi_cache_min_uses 1;
        fastcgi_cache_lock on;
        
        # Cache bypass conditions
        set \$skip_cache 0;
        
        # POST requests and URLs with query string should always go to PHP
        if (\$request_method = POST) {
            set \$skip_cache 1;
        }
        if (\$query_string != "") {
            set \$skip_cache 1;
        }
        
        # Don't cache URLs containing the following segments
        if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
            set \$skip_cache 1;
        }
        
        # Don't use the cache for logged-in users or recent commenters
        if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
            set \$skip_cache 1;
        }
        
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        
        # Buffer settings for better performance
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    
    # API endpoints - shorter cache
    location ~ ^/wp-json/ {
        try_files \$uri \$uri/ /index.php?\$args;
        
        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass ${WP_CONTAINER}:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
            fastcgi_read_timeout 300;
            
            # Short cache for API endpoints
            fastcgi_cache WORDPRESS;
            fastcgi_cache_valid 200 5m;
            
            # Cache bypass conditions
            set \$skip_cache 0;
            if (\$request_method = POST) {
                set \$skip_cache 1;
            }
            if (\$query_string != "") {
                set \$skip_cache 1;
            }
            
            fastcgi_cache_bypass \$skip_cache;
            fastcgi_no_cache \$skip_cache;
        }
    }
    
    # Deny access to sensitive files
    location ~ /\.(ht|git|svn) {
        deny all;
    }
}
EOF

        # Security config
        cat <<EOF >$CONFIG_DIR/nginx/includes/security.conf
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Performance headers
add_header X-FastCGI-Cache \$upstream_cache_status;

# Prevent access to sensitive files
location ~ /\.(?!well-known) {
    deny all;
}

# Prevent PHP execution in uploads directory
location ~* /(?:uploads|files)/.*\.php$ {
    deny all;
}

# WordPress specific optimizations
location = /favicon.ico {
    log_not_found off;
    access_log off;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
    expires 1h;
}
EOF

        # Generate entrypoint script for Nginx container
        cat <<'EOF' >$CONFIG_DIR/nginx/entrypoint.sh
#!/bin/sh

# Update /etc/hosts with any custom host mappings if needed
# This can be extended to add custom host entries based on environment variables

# Create FastCGI cache directory and set permissions
mkdir -p /var/cache/nginx/fastcgi
chown -R nginx:nginx /var/cache/nginx
chmod -R 755 /var/cache/nginx

# Create log directory if it doesn't exist
mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx

# Add FastCGI cache zone to nginx.conf if not already present
NGINX_CONF="/etc/nginx/nginx.conf"
if ! grep -q "fastcgi_cache_path" "$NGINX_CONF"; then
    # Add cache configuration to http block
    sed -i '/http {/a\
    # FastCGI Cache\
    fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;\
    fastcgi_cache_key "$scheme$request_method$host$request_uri";\
    fastcgi_cache_use_stale error timeout invalid_header http_500;\
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;' "$NGINX_CONF"
fi

# Test nginx configuration
nginx -t

# If config test passes, start nginx
if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid. Starting nginx..."
    exec nginx -g "daemon off;"
else
    echo "Nginx configuration test failed!"
    exit 1
fi
EOF

        # Make the entrypoint script executable
        chmod +x $CONFIG_DIR/nginx/entrypoint.sh

        # Generate update-hosts script for Nginx container
        cat <<'EOF' >$CONFIG_DIR/nginx/update-hosts.sh
#!/bin/sh

# Script to add paradigm_nginx container IP to /etc/hosts
# This script should be run inside the nginx container (Alpine compatible)

set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to get container IP by name
get_container_ip() {
    local container_name="$1"
    local network_name="${2:-proxy}"
    
    # Try to get IP from Docker API via host
    if command -v curl >/dev/null 2>&1; then
        # Method 1: Using Docker socket (if available)
        if [ -S /var/run/docker.sock ]; then
            local container_id=$(curl -s --unix-socket /var/run/docker.sock \
                "http://localhost/containers/json" | \
                grep -o "\"Names\":\[\"/$container_name\"\].*\"Id\":\"[^\"]*\"" | \
                grep -o "\"Id\":\"[^\"]*\"" | cut -d'"' -f4)
            
            if [ -n "$container_id" ]; then
                local ip=$(curl -s --unix-socket /var/run/docker.sock \
                    "http://localhost/containers/$container_id/json" | \
                    grep -o "\"$network_name\":{[^}]*\"IPAddress\":\"[^\"]*\"" | \
                    grep -o "\"IPAddress\":\"[^\"]*\"" | cut -d'"' -f4)
                echo "$ip"
                return 0
            fi
        fi
    fi
    
    # Method 2: Using nslookup (works in Docker networks)
    if command -v nslookup >/dev/null 2>&1; then
        local ip=$(nslookup "$container_name" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Method 3: Using getent (if available)
    if command -v getent >/dev/null 2>&1; then
        local ip=$(getent hosts "$container_name" 2>/dev/null | awk '{print $1}' | head -1)
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Method 4: Try ping and extract IP
    if command -v ping >/dev/null 2>&1; then
        local ip=$(ping -c 1 -W 2 "$container_name" 2>/dev/null | grep "PING" | grep -o "([0-9.]*)" | tr -d "()")
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    return 1
}

# Function to update /etc/hosts
update_hosts_file() {
    local container_name="$1"
    local domain_name="$2"
    local network_name="${3:-proxy}"
    
    log "Attempting to resolve IP for container: $container_name"
    
    # Get the container IP
    local container_ip=$(get_container_ip "$container_name" "$network_name")
    
    if [ -z "$container_ip" ]; then
        log "ERROR: Could not resolve IP for container: $container_name"
        return 1
    fi
    
    log "Found IP for $container_name: $container_ip"
    
    # Backup original hosts file
    if [ ! -f /etc/hosts.backup ]; then
        cp /etc/hosts /etc/hosts.backup
        log "Created backup of original /etc/hosts"
    fi
    
    # Remove any existing entries for this domain
    grep -v "$domain_name" /etc/hosts > /tmp/hosts.tmp || true
    
    # Add the new entry
    echo "$container_ip $domain_name" >> /tmp/hosts.tmp
    
    # Replace the hosts file
    mv /tmp/hosts.tmp /etc/hosts
    
    log "Updated /etc/hosts with: $container_ip $domain_name"
    
    # Verify the entry
    if grep -q "$domain_name" /etc/hosts; then
        log "SUCCESS: $domain_name entry added to /etc/hosts"
        
        # Test the resolution
        if command -v ping >/dev/null 2>&1; then
            log "Testing resolution..."
            if ping -c 1 -W 2 "$domain_name" >/dev/null 2>&1; then
                log "SUCCESS: $domain_name resolves correctly"
            else
                log "WARNING: $domain_name may not resolve correctly"
            fi
        fi
        
        return 0
    else
        log "ERROR: Failed to add entry to /etc/hosts"
        return 1
    fi
}

# Function to wait for container to be available
wait_for_container() {
    local container_name="$1"
    local max_attempts="${2:-30}"
    local attempt=1
    
    log "Waiting for container $container_name to be available..."
    
    while [ $attempt -le $max_attempts ]; do
        if get_container_ip "$container_name" >/dev/null 2>&1; then
            log "Container $container_name is available"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts: Container $container_name not yet available, waiting 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "ERROR: Container $container_name did not become available within $((max_attempts * 2)) seconds"
    return 1
}

# Main execution
main() {
    local container_name="${1:-paradigm_nginx}"
    local domain_name="${2:-paradigm.local}"
    local network_name="${3:-proxy}"
    local max_wait_attempts="${4:-30}"
    
    log "Starting hosts file update script"
    log "Target container: $container_name"
    log "Domain name: $domain_name"
    log "Network: $network_name"
    
    # Wait for the container to be available
    if ! wait_for_container "$container_name" "$max_wait_attempts"; then
        exit 1
    fi
    
    # Update the hosts file
    if update_hosts_file "$container_name" "$domain_name" "$network_name"; then
        log "Hosts file update completed successfully"
        
        # Display current /etc/hosts content for verification
        log "Current /etc/hosts content:"
        cat /etc/hosts | while read line; do
            log "  $line"
        done
        
        exit 0
    else
        log "Hosts file update failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
EOF

        # Make the update-hosts script executable
        chmod +x $CONFIG_DIR/nginx/update-hosts.sh
        ;;

    "docker-dev")
        # Get plugin mappings first to check if they exist
        local plugin_mappings=$(get_plugin_mappings)
        local vite_mappings=$(get_vite_plugin_mappings)

        cat <<EOF >docker-compose.dev.yml
services:
  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $WP_UNIT_TESTING_IMAGE
    restart: unless-stopped
    volumes:
${plugin_mappings}      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DEBUG: $WP_DEBUG
      WORDPRESS_TABLE_PREFIX: $WP_TABLE_PREFIX
      WORDPRESS_CONFIG_EXTRA: |
        define('FS_METHOD', 'direct');
        define('WP_ENVIRONMENT_TYPE', 'development');
        define('WP_CACHE', false);
      WORDPRESS_REDIS_HOST: $REDIS_CONTAINER
      DOMAIN_CURRENT_SITE: $DOMAIN
      VITE_DEV_SERVER_ADDRESS: "https://$VITE_DEV_SERVER"
    depends_on:
      - $DB_CONTAINER
    extra_hosts:
      - host.docker.internal:host-gateway
      - $DOMAIN:host-gateway

  $NGINX_CONTAINER:
    image: $NGINX_IMAGE
    container_name: $NGINX_CONTAINER
    restart: unless-stopped
    volumes:
${plugin_mappings}      - $CONFIG_DIR/nginx:/etc/nginx/conf.d
      - $CONFIG_DIR/nginx/includes:/etc/nginx/conf.d/includes
      - $CONFIG_DIR/nginx/entrypoint.sh:/docker-entrypoint.d/40-cache-setup.sh
      - $DATA_DIR/site:/var/www/html
    environment:
      VIRTUAL_HOST_MULTIPORTS: |-
        $DOMAIN:
          "/":
            port: 80
        www.$DOMAIN:
          "/":
            port: 80
    depends_on:
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 10s
      timeout: 5s
      retries: 3
    extra_hosts:
      - host.docker.internal:host-gateway
      - $DOMAIN:host-gateway

  $DB_CONTAINER:
    container_name: $DB_CONTAINER
    image: $DB_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}

  $VITE_CONTAINER:
    container_name: $VITE_CONTAINER
    user: "\${USER_ID}:\${GROUP_ID}"
    image: $VITE_IMAGE
    restart: unless-stopped
    volumes:
${vite_mappings}    working_dir: /app
    environment:
      VIRTUAL_HOST_MULTIPORTS: |-
        $VITE_DEV_SERVER:
          "/":
            port: 3000
        www.$VITE_DEV_SERVER:
          "/":
            port: 3000
      VITE_DEV_SERVER_ADDRESS: "https://$VITE_DEV_SERVER"
    command: tail -f /dev/null

networks:
  default:
    name: $DOCKER_DEV_NETWORK
    external: true
EOF
        ;;

    "docker-prod")
        cat <<EOF >docker-compose.prod.yml
services:
  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $WP_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
    environment:
      WORDPRESS_DB_HOST: \${DB_CONTAINER}:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DEBUG: $WP_DEBUG
      WORDPRESS_TABLE_PREFIX: $WP_TABLE_PREFIX
      WORDPRESS_CONFIG_EXTRA: |
        define('FS_METHOD', 'direct');
        define('WP_ENVIRONMENT_TYPE', 'production');
      WORDPRESS_REDIS_HOST: $REDIS_CONTAINER
      DOMAIN_CURRENT_SITE: $DOMAIN
    depends_on:
      - $DB_CONTAINER

  $NGINX_CONTAINER:
    image: $NGINX_IMAGE
    container_name: $NGINX_CONTAINER
    restart: unless-stopped
    volumes:
      - $CONFIG_DIR/nginx:/etc/nginx/conf.d
      - $CONFIG_DIR/nginx/includes:/etc/nginx/conf.d/includes
      - $CONFIG_DIR/nginx/entrypoint.sh:/docker-entrypoint.d/40-cache-setup.sh
      - $DATA_DIR/site:/var/www/html
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.$PROJECT_NAME.rule=Host(\${DOMAIN}) || Host(www.\${DOMAIN})"
      - "traefik.http.routers.$PROJECT_NAME.entrypoints=websecure"
      - "traefik.http.routers.$PROJECT_NAME.tls.certresolver=production"
      - "traefik.http.routers.$PROJECT_NAME.tls=true"
    depends_on:
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 5s
      retries: 3

  $DB_CONTAINER:
    container_name: $DB_CONTAINER
    image: $DB_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}

  $WP_CLI_CONTAINER:
    container_name: $WP_CLI_CONTAINER
    image: wordpress:cli
    restart: unless-stopped
    user: "\${USER_ID}:\${GROUP_ID}"
    volumes:
      - $DATA_DIR/site:/var/www/html
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
    depends_on:
      - $DB_CONTAINER
    command: tail -f /dev/null

  $REDIS_CONTAINER:
    container_name: $REDIS_CONTAINER
    image: $REDIS_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/redis:/data
    depends_on:
      - $DB_CONTAINER
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  default:
    name: $DOCKER_PROD_NETWORK
    external: true
EOF
        ;;

    "docker-apache-dev")
        # Get plugin mappings first to check if they exist
        local plugin_mappings=$(get_plugin_mappings)
        local vite_mappings=$(get_vite_plugin_mappings)

        cat <<EOF >docker-compose-apache.dev.yml
services:
  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $APACHE_WP_IMAGE
    restart: unless-stopped
    volumes:
${plugin_mappings}      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DEBUG: $WP_DEBUG
      WORDPRESS_TABLE_PREFIX: $WP_TABLE_PREFIX
      WORDPRESS_CONFIG_EXTRA: |
        define('FS_METHOD', 'direct');
        define('WP_ENVIRONMENT_TYPE', 'development');
        define('WP_CACHE', false);
      WORDPRESS_REDIS_HOST: $REDIS_CONTAINER
      DOMAIN_CURRENT_SITE: $DOMAIN
      VITE_DEV_SERVER_ADDRESS: "https://$VITE_DEV_SERVER"
      VIRTUAL_HOST_MULTIPORTS: |-
        $DOMAIN:
          "/":
            port: 80
        www.$DOMAIN:
          "/":
            port: 80
    depends_on:
      - $DB_CONTAINER
    extra_hosts:
      - host.docker.internal:host-gateway
      - $DOMAIN:host-gateway

  $DB_CONTAINER:
    container_name: $DB_CONTAINER
    image: $DB_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}

  $WP_CLI_CONTAINER:
    container_name: $WP_CLI_CONTAINER
    image: wordpress:cli
    restart: unless-stopped
    user: "\${USER_ID}:\${GROUP_ID}"
    volumes:
      - $DATA_DIR/site:/var/www/html
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
    depends_on:
      - $DB_CONTAINER
    command: tail -f /dev/null

  $VITE_CONTAINER:
    container_name: $VITE_CONTAINER
    user: "\${USER_ID}:\${GROUP_ID}"
    image: $VITE_IMAGE
    restart: unless-stopped
    volumes:
${vite_mappings}    working_dir: /app
    environment:
      VIRTUAL_HOST_MULTIPORTS: |-
        $VITE_DEV_SERVER:
          "/":
            port: 3000
        www.$VITE_DEV_SERVER:
          "/":
            port: 3000
      VITE_DEV_SERVER_ADDRESS: "https://$VITE_DEV_SERVER"
    command: tail -f /dev/null

  $REDIS_CONTAINER:
    container_name: $REDIS_CONTAINER
    image: $REDIS_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/redis:/data
    depends_on:
      - $DB_CONTAINER
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

networks:
  default:
    name: $DOCKER_DEV_NETWORK
    external: true
EOF
        ;;

    "docker-apache-prod")
        cat <<EOF >docker-compose-apache.prod.yml
services:
  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $APACHE_WP_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
    environment:
      WORDPRESS_DB_HOST: \${DB_CONTAINER}:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
      WORDPRESS_DEBUG: false
      WORDPRESS_TABLE_PREFIX: $WP_TABLE_PREFIX
      WORDPRESS_CONFIG_EXTRA: |
        define('FS_METHOD', 'direct');
        define('WP_ENVIRONMENT_TYPE', 'production');
      WORDPRESS_REDIS_HOST: $REDIS_CONTAINER
      DOMAIN_CURRENT_SITE: $DOMAIN
    depends_on:
      - $DB_CONTAINER
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.$PROJECT_NAME.loadbalancer.server.port=80"
      - "traefik.http.routers.$PROJECT_NAME.rule=Host(\${DOMAIN}) || Host(www.\${DOMAIN})"
      - "traefik.http.routers.$PROJECT_NAME.entrypoints=websecure"
      - "traefik.http.routers.$PROJECT_NAME.tls.certresolver=production"
      - "traefik.http.routers.$PROJECT_NAME.tls=true"

  $DB_CONTAINER:
    container_name: $DB_CONTAINER
    image: $DB_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}

  $WP_CLI_CONTAINER:
    container_name: $WP_CLI_CONTAINER
    image: wordpress:cli
    restart: unless-stopped
    user: "\${USER_ID}:\${GROUP_ID}"
    volumes:
      - $DATA_DIR/site:/var/www/html
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
    depends_on:
      - $DB_CONTAINER
    command: tail -f /dev/null

  $REDIS_CONTAINER:
    container_name: $REDIS_CONTAINER
    image: $REDIS_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/redis:/data
    depends_on:
      - $DB_CONTAINER
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  default:
    name: $DOCKER_PROD_NETWORK
    external: true
EOF
        ;;

    esac

    log_success "$config_type configurations generated!"
}

# Simplify repetitive code by modularizing and using helper functions

# Helper function to handle remote database operations
db_operation() {
    local operation=$1
    local ssh_host=${2:-$REMOTE_SSH_HOST}
    local db_container=${3:-$REMOTE_DB_CONTAINER}
    local db_user=${4:-$REMOTE_DB_USER}
    local db_pass=${5:-$REMOTE_DB_PASSWORD}
    local db_name=${6:-$REMOTE_DB_NAME}

    case $operation in
    "pull")
        log_info "Pulling database from remote server..."
        ssh $ssh_host "docker exec $db_container mysqldump -u$db_user -p$db_pass $db_name" >dump.sql
        docker exec -i $DB_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE <dump.sql
        docker exec $WP_CLI_CONTAINER wp search-replace "$REMOTE_DOMAIN" "$LOCAL_DOMAIN" --all-tables
        log_success "Database pull complete!"
        ;;
    "push")
        log_info "Pushing database to remote server..."
        docker exec $WP_CLI_CONTAINER wp search-replace "$LOCAL_DOMAIN" "$REMOTE_DOMAIN" --all-tables
        docker exec $DB_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE >dump.sql
        cat dump.sql | ssh $ssh_host "docker exec -i $db_container mysql -u$db_user -p$db_pass $db_name"
        docker exec $WP_CLI_CONTAINER wp search-replace "$REMOTE_DOMAIN" "$LOCAL_DOMAIN" --all-tables
        log_success "Database push complete!"
        ;;
    *)
        log_error "Invalid database operation: $operation"
        ;;
    esac
}

# Remote database operations submenu
remote_db_sync_menu() {
    while true; do
        # Display current configuration info with enhanced Gum styling
        echo
        gum style --border double --border-foreground "#04B575" --padding "1 2" --margin "0 1" --align center "Remote Database Sync Configuration"
        echo

        # Create side-by-side comparison using Gum join
        local remote_config=$(gum style \
            --border rounded \
            --border-foreground "#FF6B6B" \
            --padding "1 2" \
            --margin "0 1" \
            --width 35 \
            --bold \
            "🌐 Remote Server Details" \
            "" \
            "$(gum style --foreground "#FFD93D" "SSH Host:") $REMOTE_SSH_HOST" \
            "$(gum style --foreground "#FFD93D" "DB Container:") $REMOTE_DB_CONTAINER" \
            "$(gum style --foreground "#FFD93D" "DB User:") $REMOTE_DB_USER" \
            "$(gum style --foreground "#FFD93D" "DB Name:") $REMOTE_DB_NAME")

        local local_config=$(gum style \
            --border rounded \
            --border-foreground "#04B575" \
            --padding "1 2" \
            --margin "0 1" \
            --width 35 \
            --bold \
            "🏠 Local Server Details" \
            "" \
            "$(gum style --foreground "#6BCF7F" "DB Container:") $DB_CONTAINER" \
            "$(gum style --foreground "#6BCF7F" "DB User:") $MYSQL_USER" \
            "$(gum style --foreground "#6BCF7F" "DB Name:") $MYSQL_DATABASE" \
            "")

        # Join the two configuration blocks side by side
        gum join --horizontal --align top "$remote_config" "$local_config"
        echo

        local options=(
            "⬇️  Pull database from remote server"
            "⬆️  Push database to remote server"
            "🔍  Search and replace domain in database"
            "💾  Export database"
            "📥  Import database"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Remote Database Operations" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Pull database from remote server"*)
            log_warning "WARNING: This action will overwrite your local database entirely with the remote database!"
            read -p "Continue? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                db_operation "pull"
            fi
            ;;
        *"Push database to remote server"*)
            log_warning "WARNING: This action will overwrite your remote database entirely with the local database!"
            read -p "Continue? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                db_operation "push"
            fi
            ;;
        *"Search and replace domain in database"*)
            local search_str replace_str
            search_str=$(gum_input "Enter search string" "")
            if [[ -z "$search_str" ]]; then continue; fi

            replace_str=$(gum_input "Enter replace string" "")
            if [[ -z "$replace_str" ]]; then continue; fi

            if [[ -z "$search_str" || -z "$replace_str" ]]; then
                log_error "Both search and replace strings are required!"
            else
                docker exec $WP_CLI_CONTAINER wp search-replace "$search_str" "$replace_str" --all-tables
                log_success "Search and replace complete!"
            fi
            ;;
        *"Export database"*)
            local filename
            filename=$(gum_input "Enter output filename" "${PROJECT_NAME}_db_backup.sql")
            if [[ -z "$filename" ]]; then continue; fi

            docker exec $DB_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE >"$filename"
            log_success "Database exported to $filename!"
            ;;
        *"Import database"*)
            local filename
            filename=$(gum_input "Enter input filename" "")
            if [[ -z "$filename" ]]; then continue; fi

            if [[ -z "$filename" ]]; then
                log_error "Filename is required!"
            elif [[ ! -f "$filename" ]]; then
                log_error "File not found: $filename"
            else
                docker exec -i $DB_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE <"$filename"
                log_success "Database imported from $filename!"
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Main menu using gum interface
show_menu() {
    local options=(
        "✅  Check requirements"
        "⚙️  Configure project settings"
        "🔧  Configure advanced settings"
        "🌐  Configure remote server settings"
        "📁  Create required directories"
        "🔗  Manage proxy container"
        "🔐  Generate certificates using mkcert"
        "🏠  Manage hosts file"
        "📄  Generate .env file"
        "🌐  Generate nginx.conf file"
        "🐘  Generate PHP configs"
        "🛠️  Generate development docker-compose.dev.yml file"
        "🚀  Generate production docker-compose.prod.yml file"
        "🐧  Generate Apache development docker-compose-apache.dev.yml file"
        "⚡  Generate Apache production docker-compose-apache.prod.yml file"
        "🐳  Docker operations menu"
        "🔧  WordPress CLI menu"
        "🔄  Remote sync operations menu"
        "💾  Remote database sync menu"
        "📋  Generate WP-CLI aliases file"
        "📊  List all docker networks"
        "🌐  Create docker network"
        "🎯  Manage Docker images menu"
        "🚪  Exit"
    )

    local choice
    choice=$(gum_menu "WordPress Docker Environment - Main Menu" "${options[@]}")

    clear

    if [[ $? -ne 0 ]]; then
        log_info "Exiting..."
        exit 0
    fi

    # Execute selected option
    case "$choice" in
    *"Check requirements"*)
        check_requirements
        ;;
    *"Configure project settings"*)
        configure_project
        ;;
    *"Configure advanced settings"*)
        configure_advanced
        ;;
    *"Configure remote server settings"*)
        configure_remote_server
        ;;
    *"Create required directories"*)
        create_directories
        ;;
    *"Manage proxy container"*)
        manage_proxy_container
        ;;
    *"Generate certificates using mkcert"*)
        generate_certs
        ;;
    *"Manage hosts file"*)
        manage_hosts_file
        ;;
    *"Generate .env file"*)
        generate_configs "env"
        ;;
    *"Generate nginx.conf file"*)
        generate_configs "nginx"
        ;;
    *"Generate PHP configs"*)
        generate_configs "php"
        ;;
    *"Generate development docker-compose.dev.yml file"*)
        generate_configs "docker-dev"
        ;;
    *"Generate production docker-compose.prod.yml file"*)
        generate_configs "docker-prod"
        ;;
    *"Generate Apache development docker-compose-apache.dev.yml file"*)
        generate_configs "docker-apache-dev"
        ;;
    *"Generate Apache production docker-compose-apache.prod.yml file"*)
        generate_configs "docker-apache-prod"
        ;;
    *"Docker operations menu"*)
        configure_docker_menu
        ;;
    *"WordPress CLI menu"*)
        configure_wpcli_menu
        ;;
    *"Remote sync operations menu"*)
        remote_sync_menu
        ;;
    *"Remote database sync menu"*)
        remote_db_sync_menu
        ;;
    *"Generate WP-CLI aliases file"*)
        mkdir -p ~/.wp-cli
        cat <<EOF >~/.wp-cli/config.yml
@$PROJECT_NAME:
  ssh: ''
  path: /var/www/html
EOF
        log_success "WP-CLI aliases file generated!"
        ;;
    *"List all docker networks"*)
        clear
        log_info "Docker Networks:"
        docker network ls
        read -p "Press Enter to continue..." enter_key
        ;;
    *"Create docker network"*)
        createDockerNetwork
        ;;
    *"Manage Docker images menu"*)
        manage_docker_images_menu
        ;;
    *"Exit"*)
        log_info "Exiting..."
        exit 0
        ;;
    *)
        log_warning "Invalid option: $choice"
        ;;
    esac

    return 0
}

# Remote sync submenu
remote_sync_menu() {
    while true; do
        local options=(
            "🔌  Sync plugins from remote server"
            "🎨  Sync themes from remote server"
            "📂  Sync uploads from remote server"
            "🔄  Sync all content from remote server"
            "⚙️  Custom sync operation"
            "🔙  Back to main menu"
        )

        local choice
        choice=$(gum_menu "Remote Sync Operations" "${options[@]}")

        # Exit if no selection or user pressed Esc
        if [[ -z "$choice" || "$choice" == *"Back to main menu"* ]]; then
            return 0
        fi

        case "$choice" in
        *"Sync plugins from remote server"*)
            local remote_host remote_path
            remote_host=$(gum_input "Enter remote host" "$REMOTE_SSH_HOST")
            if [[ -z "$remote_host" ]]; then continue; fi

            remote_path=$(gum_input "Enter remote path" "$REMOTE_PROJECT_PATH")
            if [[ -z "$remote_path" ]]; then continue; fi

            handleRemoteSync "plugins" "$remote_host" "$remote_path"
            log_success "Plugins sync complete!"
            ;;
        *"Sync themes from remote server"*)
            local remote_host remote_path
            remote_host=$(gum_input "Enter remote host" "$REMOTE_SSH_HOST")
            if [[ -z "$remote_host" ]]; then continue; fi

            remote_path=$(gum_input "Enter remote path" "$REMOTE_PROJECT_PATH")
            if [[ -z "$remote_path" ]]; then continue; fi

            handleRemoteSync "themes" "$remote_host" "$remote_path"
            log_success "Themes sync complete!"
            ;;
        *"Sync uploads from remote server"*)
            local remote_host remote_path
            remote_host=$(gum_input "Enter remote host" "$REMOTE_SSH_HOST")
            if [[ -z "$remote_host" ]]; then continue; fi

            remote_path=$(gum_input "Enter remote path" "$REMOTE_PROJECT_PATH")
            if [[ -z "$remote_path" ]]; then continue; fi

            handleRemoteSync "uploads" "$remote_host" "$remote_path"
            log_success "Uploads sync complete!"
            ;;
        *"Sync all content from remote server"*)
            local remote_host remote_path
            remote_host=$(gum_input "Enter remote host" "$REMOTE_SSH_HOST")
            if [[ -z "$remote_host" ]]; then continue; fi

            remote_path=$(gum_input "Enter remote path" "$REMOTE_PROJECT_PATH")
            if [[ -z "$remote_path" ]]; then continue; fi

            handleRemoteSync "all" "$remote_host" "$remote_path"
            log_success "All content sync complete!"
            ;;
        *"Custom sync operation"*)
            local remote_host remote_custom_path local_custom_path
            remote_host=$(gum_input "Enter remote host" "$REMOTE_SSH_HOST")
            if [[ -z "$remote_host" ]]; then continue; fi

            remote_custom_path=$(gum_input "Enter remote custom path" "")
            if [[ -z "$remote_custom_path" ]]; then continue; fi

            local_custom_path=$(gum_input "Enter local custom path" "")
            if [[ -z "$local_custom_path" ]]; then continue; fi

            handleRemoteSync "custom" "$remote_host" "$remote_custom_path" "$local_custom_path"
            log_success "Custom sync complete!"
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Handle remote sync operations
handleRemoteSync() {
    local sync_type=$1
    local remote_host=$2
    local remote_path=$3
    local local_custom_path=$4

    case "$sync_type" in
    "plugins")
        log_info "Syncing plugins from $remote_host:$remote_path/wp-content/plugins/ to $DATA_DIR/site/wp-content/plugins/"
        rsync -avz --delete "$remote_host:$remote_path/wp-content/plugins/" "$DATA_DIR/site/wp-content/plugins/"
        log_success "Plugins sync complete!"
        ;;
    "themes")
        log_info "Syncing themes from $remote_host:$remote_path/wp-content/themes/ to $DATA_DIR/site/wp-content/themes/"
        rsync -avz --delete "$remote_host:$remote_path/wp-content/themes/" "$DATA_DIR/site/wp-content/themes/"
        log_success "Themes sync complete!"
        ;;
    "uploads")
        log_info "Syncing uploads from $remote_host:$remote_path/wp-content/uploads/ to $DATA_DIR/site/wp-content/uploads/"
        rsync -avz --delete "$remote_host:$remote_path/wp-content/uploads/" "$DATA_DIR/site/wp-content/uploads/"
        log_success "Uploads sync complete!"
        ;;
    "all")
        log_info "Syncing all content from $remote_host:$remote_path/wp-content/ to $DATA_DIR/site/wp-content/"
        rsync -avz --delete "$remote_host:$remote_path/wp-content/" "$DATA_DIR/site/wp-content/"
        log_success "All content sync complete!"
        ;;
    "custom")
        log_info "Syncing custom path from $remote_host:$remote_path to $local_custom_path"
        rsync -avz --delete "$remote_host:$remote_path" "$local_custom_path"
        log_success "Custom sync complete!"
        ;;
    *)
        log_error "Invalid sync type: $sync_type"
        ;;
    esac
}

# Handle docker operations
handleDocker() {
    local action=$1
    local container=$2

    case "$action" in
    "build")
        log_info "Building and starting containers..."
        docker compose up -d --build
        log_success "Containers started!"
        ;;
    "stop")
        log_info "Stopping containers..."
        docker compose stop
        log_success "Containers stopped!"
        ;;
    "start")
        log_info "Starting containers..."
        docker compose start
        log_success "Containers started!"
        ;;
    "restart")
        log_info "Restarting containers..."
        docker compose restart
        log_success "Containers restarted!"
        ;;
    "remove")
        log_info "Removing containers..."
        docker compose down
        log_success "Containers removed!"
        ;;
    "logs")
        case "$container" in
        "wp")
            docker logs -f ${WP_CONTAINER}
            ;;
        "db")
            docker logs -f ${DB_CONTAINER}
            ;;
        "nginx")
            docker logs -f ${NGINX_CONTAINER}
            ;;
        "redis")
            docker logs -f ${REDIS_CONTAINER}
            ;;
        "vite")
            docker logs -f ${VITE_CONTAINER}
            ;;
        *)
            log_error "Invalid container: $container. Choose one of: wp, db, nginx, redis, vite"
            ;;
        esac
        ;;
    "shell")
        case "$container" in
        "wp")
            docker exec -it ${WP_CONTAINER} /bin/bash
            ;;
        "db")
            docker exec -it ${DB_CONTAINER} /bin/bash
            ;;
        "nginx")
            docker exec -it ${NGINX_CONTAINER} /bin/sh
            ;;
        "redis")
            docker exec -it ${REDIS_CONTAINER} /bin/sh
            ;;
        "vite")
            docker exec -it ${VITE_CONTAINER} /bin/sh
            ;;
        "wpcli")
            docker exec -it ${WP_CLI_CONTAINER} /bin/bash
            ;;
        *)
            log_error "Invalid container: $container. Choose one of: wp, db, nginx, redis, vite, wpcli"
            ;;
        esac
        ;;
    *)
        log_error "Invalid action: $action"
        ;;
    esac
}

# Handle WP-CLI operations
handleWpCli() {
    local action=$1
    shift

    case "$action" in
    "install")
        log_info "Installing WordPress..."
        local site_title=$(prompt_with_default "Site title" "WordPress Site")
        local admin_user=$(prompt_with_default "Admin user" "admin")
        local admin_password=$(prompt_with_default "Admin password" "admin")
        local admin_email=$(prompt_with_default "Admin email" "admin@example.com")

        run_wp_cli_command "core install --url=\"http://${DOMAIN}\" --title=\"$site_title\" --admin_user=\"$admin_user\" --admin_password=\"$admin_password\" --admin_email=\"$admin_email\"" "WordPress installed successfully!"
        ;;
    "create-user")
        username="$1"
        email="$2"
        role="${3:-subscriber}"
        password="${4:-password}"

        run_wp_cli_command "user create \"$username\" \"$email\" --role=\"$role\" --user_pass=\"$password\"" "User $username created successfully!"
        ;;
    "install-plugin")
        plugin="$1"
        log_info "Installing plugin: $plugin..."
        run_wp_cli_command "plugin install \"$plugin\" --activate" "Plugin $plugin installed and activated!"
        ;;
    "install-theme")
        theme="$1"
        log_info "Installing theme: $theme..."
        run_wp_cli_command "theme install \"$theme\" --activate" "Theme $theme installed and activated!"
        ;;
    "debug-on")
        log_info "Enabling WordPress debugging..."
        local debug_settings=(
            "WP_DEBUG true"
            "WP_DEBUG_LOG true"
            "WP_DEBUG_DISPLAY true"
            "SCRIPT_DEBUG true"
        )

        for setting in "${debug_settings[@]}"; do
            read -r name value <<<"$setting"
            run_wp_cli_command "config set $name $value --raw" ""
        done
        log_success "Debugging enabled!"
        ;;
    "debug-off")
        log_info "Disabling WordPress debugging..."
        local debug_settings=(
            "WP_DEBUG false"
            "WP_DEBUG_LOG false"
            "WP_DEBUG_DISPLAY false"
            "SCRIPT_DEBUG false"
        )

        for setting in "${debug_settings[@]}"; do
            read -r name value <<<"$setting"
            run_wp_cli_command "config set $name $value --raw" ""
        done
        log_success "Debugging disabled!"
        ;;
    "custom")
        custom_cmd="$1"
        log_info "Running custom command: $custom_cmd"
        run_wp_cli_command "$custom_cmd" "Command executed!"
        ;;
    *)
        log_error "Invalid action: $action"
        ;;
    esac
}

# Create Docker network
createDockerNetwork() {
    log_info "Creating Docker network: $DOCKER_DEV_NETWORK"
    if ! docker network inspect "$DOCKER_DEV_NETWORK" &>/dev/null; then
        docker network create "$DOCKER_DEV_NETWORK"
        log_success "Network created: $DOCKER_DEV_NETWORK"
    else
        log_warning "Network $DOCKER_DEV_NETWORK already exists"
    fi
}

# Main function
main() {
    # Show enhanced header
    show_header

    # Check system requirements
    check_requirements

    # Check if this is the first run
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "First time setup detected."
        log_info "Let's configure your WordPress environment."
        configure_project
    fi

    # Ensure PHP configurations are regenerated
    generate_configs "php"

    # Keep showing menu until user exits
    while true; do
        show_menu
        read -p "Press Enter to continue..." enter_key
    done
}

# Start the script
main
