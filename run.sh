#!/usr/bin/env bash

set -e # Exit on error

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
NODE_IMAGE=${NODE_IMAGE:-"node:23-alpine"}
REDIS_IMAGE=${REDIS_IMAGE:-"redis:alpine"}

# Directory paths
DATA_DIR=${DATA_DIR:-"./data"}
CONFIG_DIR=${CONFIG_DIR:-"./config"}
DOCKER_DIR=${DOCKER_DIR:-"./docker"}

# Database settings
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root_password"}
MYSQL_DATABASE=${MYSQL_DATABASE:-"wordpress"}
MYSQL_USER=${MYSQL_USER:-"wordpress"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"wordpress"}

# WordPress settings
WP_TABLE_PREFIX=${WP_TABLE_PREFIX:-"wp_"}
WP_DEBUG=${WP_DEBUG:-"true"}
WP_DEBUG_DISPLAY=${WP_DEBUG_DISPLAY:-"true"}
WP_DEBUG_LOG=${WP_DEBUG_LOG:-"true"}
WP_SAVEQUERIES=${WP_SAVEQUERIES:-"true"}
WP_SCRIPT_DEBUG=${WP_SCRIPT_DEBUG:-"true"}

# Docker networks
DOCKER_DEV_NETWORK=${DOCKER_DEV_NETWORK:-"wp_network"}
DOCKER_PROD_NETWORK=${DOCKER_PROD_NETWORK:-"traefik_network"}

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
REMOTE_SSH_HOST=${REMOTE_SSH_HOST:-"gcloud"}
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

# ANSI color codes for better visual feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m' # Changed from light blue to cyan for better visibility
NC='\033[0m'      # No Color

# Common utility functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Additional utility functions for DRY code
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    read -rp "$prompt [$default]: " result
    echo "${result:-$default}"
}

run_wp_cli_command() {
    local cmd="$1"
    local success_msg="$2"

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
}

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
NODE_IMAGE="$NODE_IMAGE"
REDIS_IMAGE="$REDIS_IMAGE"

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
    local options=(
        "1" "Project name: $PROJECT_NAME"
        "2" "Domain: $DOMAIN"
        "3" "Vite dev server: $VITE_DEV_SERVER"
        "4" "MySQL database: $MYSQL_DATABASE"
        "5" "MySQL user: $MYSQL_USER"
        "6" "MySQL password: $MYSQL_PASSWORD"
        "7" "MySQL root password: $MYSQL_ROOT_PASSWORD"
        "8" "Docker dev network: $DOCKER_DEV_NETWORK"
        "9" "Save configuration and return"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Project Configuration" \
            --nocancel \
            --menu "Select setting to modify:" 20 70 9 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" ]]; then
            return 0
        fi

        case $choice in
        "1")
            local new_project_name
            new_project_name=$(whiptail --title "Project Name" --nocancel --inputbox "Enter project name:" 10 60 "$PROJECT_NAME" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_project_name" ]]; then
                PROJECT_NAME="$new_project_name"
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
                options[1]="Project name: $PROJECT_NAME"
            fi
            ;;
        "2")
            local new_domain
            new_domain=$(whiptail --title "Domain" --nocancel --inputbox "Enter domain:" 10 60 "$DOMAIN" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_domain" ]]; then
                DOMAIN="$new_domain"
                # Update local domain if it matches the default
                if [[ "$LOCAL_DOMAIN" == "example.local" ]]; then
                    LOCAL_DOMAIN="$DOMAIN"
                fi
                options[3]="Domain: $DOMAIN"
            fi
            ;;
        "3")
            local new_vite_dev_server
            new_vite_dev_server=$(whiptail --title "Vite Dev Server" --nocancel --inputbox "Enter Vite dev server domain:" 10 60 "$VITE_DEV_SERVER" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_vite_dev_server" ]]; then
                VITE_DEV_SERVER="$new_vite_dev_server"
                options[5]="Vite dev server: $VITE_DEV_SERVER"
            fi
            ;;
        "4")
            local new_mysql_database
            new_mysql_database=$(whiptail --title "MySQL Database" --nocancel --inputbox "Enter MySQL database name:" 10 60 "$MYSQL_DATABASE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_mysql_database" ]]; then
                MYSQL_DATABASE="$new_mysql_database"
                options[7]="MySQL database: $MYSQL_DATABASE"
            fi
            ;;
        "5")
            local new_mysql_user
            new_mysql_user=$(whiptail --title "MySQL User" --nocancel --inputbox "Enter MySQL user:" 10 60 "$MYSQL_USER" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_mysql_user" ]]; then
                MYSQL_USER="$new_mysql_user"
                options[9]="MySQL user: $MYSQL_USER"
            fi
            ;;
        "6")
            local new_mysql_password
            new_mysql_password=$(whiptail --title "MySQL Password" --nocancel --passwordbox "Enter MySQL password:" 10 60 "$MYSQL_PASSWORD" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_mysql_password" ]]; then
                MYSQL_PASSWORD="$new_mysql_password"
                options[11]="MySQL password: $MYSQL_PASSWORD"
            fi
            ;;
        "7")
            local new_mysql_root_password
            new_mysql_root_password=$(whiptail --title "MySQL Root Password" --nocancel --passwordbox "Enter MySQL root password:" 10 60 "$MYSQL_ROOT_PASSWORD" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_mysql_root_password" ]]; then
                MYSQL_ROOT_PASSWORD="$new_mysql_root_password"
                options[13]="MySQL root password: $MYSQL_ROOT_PASSWORD"
            fi
            ;;
        "8")
            local new_docker_dev_network
            new_docker_dev_network=$(whiptail --title "Docker Dev Network" --nocancel --inputbox "Enter Docker dev network name:" 10 60 "$DOCKER_DEV_NETWORK" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_docker_dev_network" ]]; then
                DOCKER_DEV_NETWORK="$new_docker_dev_network"
                options[15]="Docker dev network: $DOCKER_DEV_NETWORK"
            fi
            ;;
        "9")
            save_config
            log_success "Configuration saved!"
            return 0
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Configure advanced settings menu
configure_advanced() {
    local options=(
        "1" "WordPress production image: $WP_IMAGE"
        "2" "WordPress dev image: $WP_UNIT_TESTING_IMAGE"
        "3" "DB image: $DB_IMAGE"
        "4" "Nginx image: $NGINX_IMAGE"
        "5" "Node image: $NODE_IMAGE"
        "6" "Redis image: $REDIS_IMAGE"
        "7" "Data directory: $DATA_DIR"
        "8" "Config directory: $CONFIG_DIR"
        "9" "Docker directory: $DOCKER_DIR"
        "10" "WordPress table prefix: $WP_TABLE_PREFIX"
        "11" "WordPress debug: $WP_DEBUG"
        "12" "Production Docker network: $DOCKER_PROD_NETWORK"
        "13" "Save configuration and return"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Advanced Configuration" \
            --nocancel \
            --menu "Select setting to modify:" 20 76 13 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" ]]; then
            return 0
        fi

        case $choice in
        "1")
            local new_wp_image
            new_wp_image=$(whiptail --title "WordPress Production Image" --nocancel --inputbox "Enter WordPress production image:" 10 60 "$WP_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_wp_image" ]]; then
                WP_IMAGE="$new_wp_image"
                options[1]="WordPress production image: $WP_IMAGE"
            fi
            ;;
        "2")
            local new_wp_unit_testing_image
            new_wp_unit_testing_image=$(whiptail --title "WordPress Dev Image" --nocancel --inputbox "Enter WordPress dev image:" 10 60 "$WP_UNIT_TESTING_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_wp_unit_testing_image" ]]; then
                WP_UNIT_TESTING_IMAGE="$new_wp_unit_testing_image"
                options[3]="WordPress dev image: $WP_UNIT_TESTING_IMAGE"
            fi
            ;;
        "3")
            local new_db_image
            new_db_image=$(whiptail --title "DB Image" --nocancel --inputbox "Enter DB image:" 10 60 "$DB_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_db_image" ]]; then
                DB_IMAGE="$new_db_image"
                options[5]="DB image: $DB_IMAGE"
            fi
            ;;
        "4")
            local new_nginx_image
            new_nginx_image=$(whiptail --title "Nginx Image" --nocancel --inputbox "Enter Nginx image:" 10 60 "$NGINX_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_nginx_image" ]]; then
                NGINX_IMAGE="$new_nginx_image"
                options[7]="Nginx image: $NGINX_IMAGE"
            fi
            ;;
        "5")
            local new_node_image
            new_node_image=$(whiptail --title "Node Image" --nocancel --inputbox "Enter Node image:" 10 60 "$NODE_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_node_image" ]]; then
                NODE_IMAGE="$new_node_image"
                options[9]="Node image: $NODE_IMAGE"
            fi
            ;;
        "6")
            local new_redis_image
            new_redis_image=$(whiptail --title "Redis Image" --nocancel --inputbox "Enter Redis image:" 10 60 "$REDIS_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_redis_image" ]]; then
                REDIS_IMAGE="$new_redis_image"
                options[11]="Redis image: $REDIS_IMAGE"
            fi
            ;;
        "7")
            local new_data_dir
            new_data_dir=$(whiptail --title "Data Directory" --nocancel --inputbox "Enter data directory path:" 10 60 "$DATA_DIR" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_data_dir" ]]; then
                DATA_DIR="$new_data_dir"
                options[13]="Data directory: $DATA_DIR"
            fi
            ;;
        "8")
            local new_config_dir
            new_config_dir=$(whiptail --title "Config Directory" --nocancel --inputbox "Enter config directory path:" 10 60 "$CONFIG_DIR" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_config_dir" ]]; then
                CONFIG_DIR="$new_config_dir"
                options[15]="Config directory: $CONFIG_DIR"
            fi
            ;;
        "9")
            local new_docker_dir
            new_docker_dir=$(whiptail --title "Docker Directory" --nocancel --inputbox "Enter docker directory path:" 10 60 "$DOCKER_DIR" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_docker_dir" ]]; then
                DOCKER_DIR="$new_docker_dir"
                options[17]="Docker directory: $DOCKER_DIR"
            fi
            ;;
        "10")
            local new_wp_table_prefix
            new_wp_table_prefix=$(whiptail --title "WordPress Table Prefix" --nocancel --inputbox "Enter WordPress table prefix:" 10 60 "$WP_TABLE_PREFIX" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_wp_table_prefix" ]]; then
                WP_TABLE_PREFIX="$new_wp_table_prefix"
                options[19]="WordPress table prefix: $WP_TABLE_PREFIX"
            fi
            ;;
        "11")
            local new_wp_debug
            new_wp_debug=$(whiptail --title "WordPress Debug" --nocancel --inputbox "Enter WordPress debug (true/false):" 10 60 "$WP_DEBUG" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_wp_debug" ]]; then
                WP_DEBUG="$new_wp_debug"
                options[21]="WordPress debug: $WP_DEBUG"
            fi
            ;;
        "12")
            local new_docker_prod_network
            new_docker_prod_network=$(whiptail --title "Production Docker Network" --nocancel --inputbox "Enter production Docker network:" 10 60 "$DOCKER_PROD_NETWORK" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_docker_prod_network" ]]; then
                DOCKER_PROD_NETWORK="$new_docker_prod_network"
                options[23]="Production Docker network: $DOCKER_PROD_NETWORK"
            fi
            ;;
        "13")
            save_config
            log_success "Configuration saved!"
            return 0
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Manage hosts file submenu
manage_hosts_file() {
    local options=(
        "1" "Add domain to hosts file"
        "2" "Remove domain from hosts file"
        "3" "Check if domain exists in hosts file"
        "4" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Manage Hosts File Menu" \
            --nocancel \
            --menu "Select an option:" 15 60 4 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" || "$choice" == "4" ]]; then
            return 0
        fi

        case $choice in
        "1")
            if grep -q "$DOMAIN" /etc/hosts; then
                whiptail --title "Warning" --msgbox "Domain $DOMAIN already exists in the hosts file." 10 60
            else
                echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
                whiptail --title "Success" --msgbox "Domain $DOMAIN added to hosts file." 10 60
            fi
            ;;
        "2")
            if grep -q "$DOMAIN" /etc/hosts; then
                sudo sed -i "/$DOMAIN/d" /etc/hosts
                whiptail --title "Success" --msgbox "Domain $DOMAIN removed from hosts file." 10 60
            else
                whiptail --title "Warning" --msgbox "Domain $DOMAIN not found in the hosts file." 10 60
            fi
            ;;
        "3")
            if grep -q "$DOMAIN" /etc/hosts; then
                whiptail --title "Status" --msgbox "Domain $DOMAIN exists in the hosts file." 10 60
            else
                whiptail --title "Status" --msgbox "Domain $DOMAIN does not exist in the hosts file." 10 60
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Manage proxy container submenu
manage_proxy_container() {
    local options=(
        "1" "Run main proxy container"
        "2" "Stop and remove proxy container"
        "3" "Check proxy container status"
        "4" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Manage Proxy Container" \
            --nocancel \
            --menu "Select an option:" 15 60 4 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" || "$choice" == "4" ]]; then
            return 0
        fi

        case $choice in
        "1")
            # Check if ports 80 and 443 are free
            if lsof -i:80 -i:443 &>/dev/null; then
                whiptail --title "Error" --msgbox "Ports 80 and/or 443 are already in use. Please stop any services using these ports and try again." 10 70
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
                whiptail --title "Information" --msgbox "Proxy container $PROXY_CONTAINER_NAME is already running." 10 60
                continue
            elif docker ps -a --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_info "Container exists but is not running. Starting container..."
                docker start "$PROXY_CONTAINER_NAME"
                whiptail --title "Success" --msgbox "Proxy container $PROXY_CONTAINER_NAME started." 10 60
                continue
            fi

            # Run the proxy container
            log_info "Running the proxy container..."
            docker run --name "$PROXY_CONTAINER_NAME" --net "$PROXY_NETWORK" -d --restart=unless-stopped \
                -p 80:80 -p 443:443 \
                -v /var/run/docker.sock:/tmp/docker.sock:ro \
                -v "$PROXY_CERTS_DIR:/etc/nginx/certs" \
                "$PROXY_IMAGE"

            whiptail --title "Success" --msgbox "Proxy container $PROXY_CONTAINER_NAME is now running." 10 60
            ;;
        "2")
            # Stop and remove the proxy container
            if docker ps -a --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                log_info "Stopping and removing the proxy container..."
                docker stop "$PROXY_CONTAINER_NAME" && docker rm "$PROXY_CONTAINER_NAME"
                whiptail --title "Success" --msgbox "Proxy container $PROXY_CONTAINER_NAME stopped and removed." 10 70
            else
                whiptail --title "Warning" --msgbox "Proxy container $PROXY_CONTAINER_NAME is not running." 10 60
            fi
            ;;
        "3")
            # Check the status of the proxy container
            if docker ps --format '{{.Names}}' | grep -q "^$PROXY_CONTAINER_NAME\$"; then
                whiptail --title "Status" --msgbox "Proxy container $PROXY_CONTAINER_NAME is running." 10 60
            else
                whiptail --title "Status" --msgbox "Proxy container $PROXY_CONTAINER_NAME is not running." 10 60
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
    local options=(
        "1" "Build and start containers"
        "2" "Stop containers"
        "3" "Start containers"
        "4" "Restart containers"
        "5" "Remove containers"
        "6" "View logs"
        "7" "Access container shell"
        "8" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Docker Management Menu" \
            --nocancel \
            --menu "Select an operation:" 17 60 8 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" || "$choice" == "8" ]]; then
            return 0
        fi

        case $choice in
        "1")
            handleDocker "build"
            ;;
        "2")
            handleDocker "stop"
            ;;
        "3")
            handleDocker "start"
            ;;
        "4")
            handleDocker "restart"
            ;;
        "5")
            handleDocker "remove"
            ;;
        "6")
            local container
            container=$(whiptail --title "View Logs" --nocancel --inputbox "Enter container name (wp, db, nginx, redis, vite):" 10 60 "" 3>&1 1>&2 2>&3)
            handleDocker "logs" "$container"
            ;;
        "7")
            local container
            container=$(whiptail --title "Access Container Shell" --nocancel --inputbox "Enter container name (wp, db, nginx, redis, vite, wpcli):" 10 60 "" 3>&1 1>&2 2>&3)
            handleDocker "shell" "$container"
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# WP-CLI submenu
configure_wpcli_menu() {
    local options=(
        "1" "Install WordPress"
        "2" "Create user"
        "3" "Install plugin"
        "4" "Install theme"
        "5" "Enable debugging"
        "6" "Disable debugging"
        "7" "Run custom WP-CLI command"
        "8" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "WP-CLI Management Menu" \
            --nocancel \
            --menu "Select an operation:" 17 60 8 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" || "$choice" == "8" ]]; then
            return 0
        fi

        case $choice in
        "1")
            handleWpCli "install"
            ;;
        "2")
            local username email role password

            username=$(whiptail --title "Username" --nocancel --inputbox "Enter username:" 10 60 "" 3>&1 1>&2 2>&3)
            email=$(whiptail --title "Email" --nocancel --inputbox "Enter email:" 10 60 "" 3>&1 1>&2 2>&3)
            role=$(whiptail --title "Role" --nocancel --inputbox "Enter role:" 10 60 "subscriber" 3>&1 1>&2 2>&3)
            password=$(whiptail --title "Password" --nocancel --passwordbox "Enter password:" 10 60 "password" 3>&1 1>&2 2>&3)

            handleWpCli "create-user" "$username" "$email" "$role" "$password"
            ;;
        "3")
            local plugin

            plugin=$(whiptail --title "Plugin" --nocancel --inputbox "Enter plugin name:" 10 60 "" 3>&1 1>&2 2>&3)

            handleWpCli "install-plugin" "$plugin"
            ;;
        "4")
            local theme

            theme=$(whiptail --title "Theme" --nocancel --inputbox "Enter theme name:" 10 60 "" 3>&1 1>&2 2>&3)

            handleWpCli "install-theme" "$theme"
            ;;
        "5")
            handleWpCli "debug-on"
            ;;
        "6")
            handleWpCli "debug-off"
            ;;
        "7")
            local custom_cmd

            custom_cmd=$(whiptail --title "Custom Command" --nocancel --inputbox "Enter custom WP-CLI command:" 10 60 "" 3>&1 1>&2 2>&3)

            handleWpCli "custom" "$custom_cmd"
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Manage Docker images submenu
manage_docker_images_menu() {
    local options=(
        "1" "Build development image (Current: $WP_UNIT_TESTING_IMAGE)"
        "2" "Build production image (Current: $WP_IMAGE)"
        "3" "Edit image versions"
        "4" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Manage Docker Images" \
            --nocancel \
            --menu "Select an option:" 15 60 4 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        if [[ -z "$choice" || "$choice" == "4" ]]; then
            return 0
        fi

        case $choice in
        "1")
            log_info "Building development image: $WP_UNIT_TESTING_IMAGE..."
            docker build -f docker/Dockerfile.dev -t $WP_UNIT_TESTING_IMAGE .
            log_success "Development image built successfully!"
            ;;
        "2")
            log_info "Building production image: $WP_IMAGE..."
            docker build -f docker/Dockerfile.prod -t $WP_IMAGE .
            log_success "Production image built successfully!"
            ;;
        "3")
            local new_dev_image new_prod_image

            new_dev_image=$(whiptail --title "Edit Development Image" --nocancel --inputbox "Enter new development image version (Current: $WP_UNIT_TESTING_IMAGE):" 10 60 "$WP_UNIT_TESTING_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_dev_image" ]]; then
                WP_UNIT_TESTING_IMAGE="$new_dev_image"
                log_success "Development image version updated to $WP_UNIT_TESTING_IMAGE"
            fi

            new_prod_image=$(whiptail --title "Edit Production Image" --nocancel --inputbox "Enter new production image version (Current: $WP_IMAGE):" 10 60 "$WP_IMAGE" 3>&1 1>&2 2>&3)
            if [[ $? -eq 0 && -n "$new_prod_image" ]]; then
                WP_IMAGE="$new_prod_image"
                log_success "Production image version updated to $WP_IMAGE"
            fi

            # Update menu options to reflect new versions
            options[1]="1 Build development image (Current: $WP_UNIT_TESTING_IMAGE)"
            options[3]="2 Build production image (Current: $WP_IMAGE)"
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Check for required commands
check_requirements() {
    log_info "Checking requirements..."

    local required_cmds=("docker" "curl")
    local missing_cmds=()

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    if ! docker compose --version &>/dev/null; then
        missing_cmds+=("docker compose")
    fi

    if [ ${#missing_cmds[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_cmds[*]}"
        log_info "Please install them before continuing."
        exit 1
    fi

    log_success "All requirements satisfied!"
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
    new_proxy_certs_dir=$(whiptail --title "Set Proxy Certs Directory" --nocancel --inputbox "Enter the directory to save proxy certificates:" 10 60 "$default_proxy_certs_dir" 3>&1 1>&2 2>&3)
    if [[ -n "$new_proxy_certs_dir" ]]; then
        PROXY_CERTS_DIR="$new_proxy_certs_dir"
    else
        PROXY_CERTS_DIR="$default_proxy_certs_dir"
    fi

    log_info "Generating certificates using mkcert..."
    mkdir -p "$PROXY_CERTS_DIR"
    mkcert -cert-file "$PROXY_CERTS_DIR/$PROXY_CERT_FILE" -key-file "$PROXY_CERTS_DIR/$PROXY_KEY_FILE" "$DOMAIN" "*.$DOMAIN"

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
extension=mysqli
extension=exif
extension=gd
extension=intl
extension=imagick

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
extension=mysqli
extension=exif
extension=gd
extension=intl
extension=imagick
EOF
        ;;

    "nginx")
        mkdir -p "${CONFIG_DIR}/nginx" "${CONFIG_DIR}/nginx/includes"

        # Main nginx config
        cat <<EOF >$CONFIG_DIR/nginx/nginx.conf
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    root /var/www/html;
    index index.php;
    
    server_tokens off;
    include /etc/nginx/my_include_files/*.conf;
    
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
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public, max-age=2592000";
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # Pass PHP scripts to FastCGI server
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass ${WP_CONTAINER}:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_read_timeout 300;
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
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'; frame-ancestors 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval';" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Prevent access to sensitive files
location ~ /\.(?!well-known) {
    deny all;
}

# Prevent PHP execution in uploads directory
location ~* /(?:uploads|files)/.*\.php$ {
    deny all;
}
EOF
        ;;

    "docker-dev")
        cat <<EOF >docker-compose.yaml
services:
  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $WP_UNIT_TESTING_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
      - /media/anver/work/plugins:/var/www/html/wp-content/plugins-dev
      - /media/anver/work/themes:/var/www/html/wp-content/themes-dev
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

  $NGINX_CONTAINER:
    image: $NGINX_IMAGE
    container_name: $NGINX_CONTAINER
    restart: unless-stopped
    volumes:
      - $CONFIG_DIR/nginx:/etc/nginx/conf.d
      - $CONFIG_DIR/nginx/includes:/etc/nginx/my_include_files
      - $DATA_DIR/site:/var/www/html
      - /media/anver/work/plugins:/var/www/html/wp-content/plugins-dev
      - /media/anver/work/themes:/var/www/html/wp-content/themes-dev
    environment:
      - VIRTUAL_HOST=$DOMAIN,www.$DOMAIN
      - VIRTUAL_PORT=80
      - VIRTUAL_PROTO=http
    depends_on:
      - $WP_CONTAINER
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 10s
      timeout: 5s
      retries: 3

  $WP_CLI_CONTAINER:
    container_name: $WP_CLI_CONTAINER
    image: wordpress:cli
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
    image: $NODE_IMAGE
    volumes:
      - .:/app
    working_dir: /app
    command: yarn start
    environment:
      VIRTUAL_HOST: "www.$VITE_DEV_SERVER,$VITE_DEV_SERVER"
      VIRTUAL_PORT: 3000
      VIRTUAL_PROTO: http
      VITE_DEV_SERVER_ADDRESS: "https://$VITE_DEV_SERVER"

networks:
  default:
    name: $DOCKER_DEV_NETWORK
    external: true
EOF
        ;;

    "docker-prod")
        cat <<EOF >docker-compose.prod.yaml
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
      - $CONFIG_DIR/nginx/includes:/etc/nginx/my_include_files
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
    local options=(
        "1" "Pull database from remote server"
        "2" "Push database to remote server"
        "3" "Search and replace domain in database"
        "4" "Export database"
        "5" "Import database"
        "6" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Remote Database Operations" \
            --nocancel \
            --menu "\nRemote and Local Database Details:\n----------------------------------------------\n| Remote Details          | Local Details    |\n----------------------------------------------\n| SSH Host: $REMOTE_SSH_HOST | DB Container: $DB_CONTAINER |\n| DB Container: $REMOTE_DB_CONTAINER | DB User: $MYSQL_USER |\n| DB User: $REMOTE_DB_USER | DB Name: $MYSQL_DATABASE |\n| DB Name: $REMOTE_DB_NAME | Domain: $LOCAL_DOMAIN |\n| Domain: $REMOTE_DOMAIN   |                  |\n----------------------------------------------\n\nSelect an operation:" 20 70 6 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        if [[ -z "$choice" || "$choice" == "6" ]]; then
            return 0
        fi

        case $choice in
        "1")
            if whiptail --title "Warning" --yesno "This action will overwrite your local database entirely with the remote database!\n\nContinue?" 10 70; then
                db_operation "pull"
            fi
            ;;
        "2")
            if whiptail --title "Warning" --yesno "This action will overwrite your remote database entirely with the local database!\n\nContinue?" 10 70; then
                db_operation "push"
            fi
            ;;
        "3")
            local search_str replace_str
            search_str=$(whiptail --title "Search String" --nocancel --inputbox "Enter search string:" 10 60 "" 3>&1 1>&2 2>&3)
            replace_str=$(whiptail --title "Replace String" --nocancel --inputbox "Enter replace string:" 10 60 "" 3>&1 1>&2 2>&3)

            if [[ -z "$search_str" || -z "$replace_str" ]]; then
                whiptail --title "Error" --msgbox "Both search and replace strings are required!" 10 60
            else
                docker exec $WP_CLI_CONTAINER wp search-replace "$search_str" "$replace_str" --all-tables
                whiptail --title "Success" --msgbox "Search and replace complete!" 10 60
            fi
            ;;
        "4")
            local filename
            filename=$(whiptail --title "Output Filename" --nocancel --inputbox "Enter output filename:" 10 60 "${PROJECT_NAME}_db_backup.sql" 3>&1 1>&2 2>&3)
            docker exec $DB_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE >"$filename"
            whiptail --title "Success" --msgbox "Database exported to $filename!" 10 60
            ;;
        "5")
            local filename
            filename=$(whiptail --title "Input Filename" --nocancel --inputbox "Enter input filename:" 10 60 "" 3>&1 1>&2 2>&3)

            if [[ -z "$filename" ]]; then
                whiptail --title "Error" --msgbox "Filename is required!" 10 60
            elif [[ ! -f "$filename" ]]; then
                whiptail --title "Error" --msgbox "File not found: $filename" 10 60
            else
                docker exec -i $DB_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE <"$filename"
                whiptail --title "Success" --msgbox "Database imported from $filename!" 10 60
            fi
            ;;
        *)
            log_warning "Invalid choice: $choice"
            ;;
        esac
    done
}

# Simplified menu handling with checkbox-style interface using whiptail
show_menu() {
    local options=(
        "1" "Check requirements" "OFF"
        "2" "Configure project settings" "OFF"
        "3" "Configure advanced settings" "OFF"
        "4" "Create required directories" "OFF"
        "5" "Manage proxy container" "OFF"
        "6" "Generate certificates using mkcert" "OFF"
        "7" "Manage hosts file" "OFF"
        "8" "Generate .env file" "OFF"
        "9" "Generate nginx.conf file" "OFF"
        "10" "Generate PHP configs" "OFF"
        "11" "Generate development docker-compose.yml file" "OFF"
        "12" "Generate production docker-compose.yml file" "OFF"
        "13" "Docker operations menu" "OFF"
        "14" "WordPress CLI menu" "OFF"
        "15" "Remote sync operations menu" "OFF"
        "16" "Remote database sync menu" "OFF"
        "17" "Generate WP-CLI aliases file" "OFF"
        "18" "List all docker networks" "OFF"
        "19" "Create docker network" "OFF"
        "20" "Manage Docker images menu" "OFF"
        "21" "Exit" "OFF"
    )

    local choices
    choices=$(whiptail --title "WordPress Docker Environment" \
        --nocancel \
        --checklist "Select one or more options:" 20 70 15 \
        "${options[@]}" 3>&1 1>&2 2>&3)

    clear

    if [[ -z "$choices" ]]; then
        log_warning "No selection made."
        return 1
    fi

    # Execute selected options
    for choice in $(echo $choices | tr -d '"'); do
        case $choice in
        "1") check_requirements ;;
        "2") configure_project ;;
        "3") configure_advanced ;;
        "4") create_directories ;;
        "5") manage_proxy_container ;;
        "6") generate_certs ;;
        "7") manage_hosts_file ;;
        "8") generate_configs "env" ;;
        "9") generate_configs "nginx" ;;
        "10") generate_configs "php" ;;
        "11") generate_configs "docker-dev" ;;
        "12") generate_configs "docker-prod" ;;
        "13") configure_docker_menu ;;
        "14") configure_wpcli_menu ;;
        "15") remote_sync_menu ;;
        "16") remote_db_sync_menu ;;
        "17")
            mkdir -p ~/.wp-cli
            cat <<EOF >~/.wp-cli/config.yml
@$PROJECT_NAME:
  ssh: ''
  path: /var/www/html
EOF
            log_success "WP-CLI aliases file generated!"
            ;;
        "18")
            clear
            log_info "Docker Networks:"
            docker network ls
            read -p "Press Enter to continue..." enter_key
            ;;
        "19") createDockerNetwork ;;
        "20") manage_docker_images_menu ;;
        "21")
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_warning "Invalid option: $choice"
            ;;
        esac
    done

    return 0
}

# Remote sync submenu
remote_sync_menu() {
    local options=(
        "1" "Sync plugins from remote server"
        "2" "Sync themes from remote server"
        "3" "Sync uploads from remote server"
        "4" "Sync all content from remote server"
        "5" "Custom sync operation"
        "6" "Back to main menu"
    )

    while true; do
        local choice
        choice=$(whiptail --title "Remote Sync Operations" \
            --nocancel \
            --menu "Select an operation:" 16 60 6 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)

        # Exit the loop if user pressed Escape or selected nothing
        if [[ -z "$choice" || "$choice" == "6" ]]; then
            return 0
        fi

        case $choice in
        "1")
            local remote_host remote_path
            remote_host=$(whiptail --title "Remote Host" --nocancel --inputbox "Enter remote host:" 10 60 "$REMOTE_SSH_HOST" 3>&1 1>&2 2>&3)
            remote_path=$(whiptail --title "Remote Path" --nocancel --inputbox "Enter remote path:" 10 60 "$REMOTE_PROJECT_PATH" 3>&1 1>&2 2>&3)

            handleRemoteSync "plugins" "$remote_host" "$remote_path"
            whiptail --title "Success" --msgbox "Plugins sync complete!" 10 60
            ;;
        "2")
            local remote_host remote_path
            remote_host=$(whiptail --title "Remote Host" --nocancel --inputbox "Enter remote host:" 10 60 "$REMOTE_SSH_HOST" 3>&1 1>&2 2>&3)
            remote_path=$(whiptail --title "Remote Path" --nocancel --inputbox "Enter remote path:" 10 60 "$REMOTE_PROJECT_PATH" 3>&1 1>&2 2>&3)

            handleRemoteSync "themes" "$remote_host" "$remote_path"
            whiptail --title "Success" --msgbox "Themes sync complete!" 10 60
            ;;
        "3")
            local remote_host remote_path
            remote_host=$(whiptail --title "Remote Host" --nocancel --inputbox "Enter remote host:" 10 60 "$REMOTE_SSH_HOST" 3>&1 1>&2 2>&3)
            remote_path=$(whiptail --title "Remote Path" --nocancel --inputbox "Enter remote path:" 10 60 "$REMOTE_PROJECT_PATH" 3>&1 1>&2 2>&3)

            handleRemoteSync "uploads" "$remote_host" "$remote_path"
            whiptail --title "Success" --msgbox "Uploads sync complete!" 10 60
            ;;
        "4")
            local remote_host remote_path
            remote_host=$(whiptail --title "Remote Host" --nocancel --inputbox "Enter remote host:" 10 60 "$REMOTE_SSH_HOST" 3>&1 1>&2 2>&3)
            remote_path=$(whiptail --title "Remote Path" --nocancel --inputbox "Enter remote path:" 10 60 "$REMOTE_PROJECT_PATH" 3>&1 1>&2 2>&3)

            handleRemoteSync "all" "$remote_host" "$remote_path"
            whiptail --title "Success" --msgbox "All content sync complete!" 10 60
            ;;
        "5")
            local remote_host remote_custom_path local_custom_path
            remote_host=$(whiptail --title "Remote Host" --nocancel --inputbox "Enter remote host:" 10 60 "$REMOTE_SSH_HOST" 3>&1 1>&2 2>&3)
            remote_custom_path=$(whiptail --title "Remote Custom Path" --nocancel --inputbox "Enter remote custom path:" 10 60 "" 3>&1 1>&2 2>&3)
            local_custom_path=$(whiptail --title "Local Custom Path" --nocancel --inputbox "Enter local custom path:" 10 60 "" 3>&1 1>&2 2>&3)

            if [[ -n "$remote_custom_path" && -n "$local_custom_path" ]]; then
                handleRemoteSync "custom" "$remote_host" "$remote_custom_path" "$local_custom_path"
                whiptail --title "Success" --msgbox "Custom sync complete!" 10 60
            else
                whiptail --title "Error" --msgbox "Both remote and local paths are required!" 10 60
            fi
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
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        exit 1
    fi

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
