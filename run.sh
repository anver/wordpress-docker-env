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
NGINX_IMAGE=${NGINX_IMAGE:-"nginx:alpine"}
NODE_IMAGE=${NODE_IMAGE:-"node:23-alpine"}

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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    cat > "$CONFIG_FILE" <<EOF
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
EOF
    
    log_success "Configuration saved successfully!"
}

# Configure project settings menu
configure_project() {
    clear
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}         Project Configuration           ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo "Current settings:"
    echo "1. Project name: $PROJECT_NAME"
    echo "2. Domain: $DOMAIN"
    echo "3. Vite dev server: $VITE_DEV_SERVER"
    echo "4. MySQL database: $MYSQL_DATABASE"
    echo "5. MySQL user: $MYSQL_USER"
    echo "6. MySQL password: $MYSQL_PASSWORD"
    echo "7. MySQL root password: $MYSQL_ROOT_PASSWORD"
    echo "8. Docker dev network: $DOCKER_DEV_NETWORK"
    echo "9. Save configuration and return"
    echo -e "${BLUE}==========================================${NC}"
    
    read -rp "Enter your choice: " choice
    
    case $choice in
    1)
        read -rp "Project name [$PROJECT_NAME]: " new_project_name
        PROJECT_NAME=${new_project_name:-$PROJECT_NAME}
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
        configure_project
        ;;
    2)
        read -rp "Domain [$DOMAIN]: " new_domain
        DOMAIN=${new_domain:-$DOMAIN}
        # Update local domain if it matches the default
        if [[ "$LOCAL_DOMAIN" == "example.local" ]]; then
            LOCAL_DOMAIN="$DOMAIN"
        fi
        configure_project
        ;;
    3)
        read -rp "Vite dev server [$VITE_DEV_SERVER]: " new_vite_dev_server
        VITE_DEV_SERVER=${new_vite_dev_server:-$VITE_DEV_SERVER}
        configure_project
        ;;
    4)
        read -rp "MySQL database [$MYSQL_DATABASE]: " new_mysql_database
        MYSQL_DATABASE=${new_mysql_database:-$MYSQL_DATABASE}
        configure_project
        ;;
    5)
        read -rp "MySQL user [$MYSQL_USER]: " new_mysql_user
        MYSQL_USER=${new_mysql_user:-$MYSQL_USER}
        configure_project
        ;;
    6)
        read -rp "MySQL password [$MYSQL_PASSWORD]: " new_mysql_password
        MYSQL_PASSWORD=${new_mysql_password:-$MYSQL_PASSWORD}
        configure_project
        ;;
    7)
        read -rp "MySQL root password [$MYSQL_ROOT_PASSWORD]: " new_mysql_root_password
        MYSQL_ROOT_PASSWORD=${new_mysql_root_password:-$MYSQL_ROOT_PASSWORD}
        configure_project
        ;;
    8)
        read -rp "Docker dev network [$DOCKER_DEV_NETWORK]: " new_docker_dev_network
        DOCKER_DEV_NETWORK=${new_docker_dev_network:-$DOCKER_DEV_NETWORK}
        configure_project
        ;;
    9)
        save_config
        return
        ;;
    *)
        log_warning "Invalid choice: $choice"
        configure_project
        ;;
    esac
}

# Configure advanced settings menu
configure_advanced() {
    clear
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       Advanced Configuration            ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo "Current settings:"
    echo "1. WordPress image: $WP_IMAGE"
    echo "2. DB image: $DB_IMAGE"
    echo "3. Nginx image: $NGINX_IMAGE"
    echo "4. Node image: $NODE_IMAGE"
    echo "5. Data directory: $DATA_DIR"
    echo "6. Config directory: $CONFIG_DIR"
    echo "7. Docker directory: $DOCKER_DIR"
    echo "8. WordPress table prefix: $WP_TABLE_PREFIX"
    echo "9. WordPress debug: $WP_DEBUG"
    echo "10. Production Docker network: $DOCKER_PROD_NETWORK"
    echo "11. Save configuration and return"
    echo -e "${BLUE}==========================================${NC}"
    
    read -rp "Enter your choice: " choice
    
    case $choice in
    1)
        read -rp "WordPress image [$WP_IMAGE]: " new_wp_image
        WP_IMAGE=${new_wp_image:-$WP_IMAGE}
        configure_advanced
        ;;
    2)
        read -rp "DB image [$DB_IMAGE]: " new_db_image
        DB_IMAGE=${new_db_image:-$DB_IMAGE}
        configure_advanced
        ;;
    3)
        read -rp "Nginx image [$NGINX_IMAGE]: " new_nginx_image
        NGINX_IMAGE=${new_nginx_image:-$NGINX_IMAGE}
        configure_advanced
        ;;
    4)
        read -rp "Node image [$NODE_IMAGE]: " new_node_image
        NODE_IMAGE=${new_node_image:-$NODE_IMAGE}
        configure_advanced
        ;;
    5)
        read -rp "Data directory [$DATA_DIR]: " new_data_dir
        DATA_DIR=${new_data_dir:-$DATA_DIR}
        configure_advanced
        ;;
    6)
        read -rp "Config directory [$CONFIG_DIR]: " new_config_dir
        CONFIG_DIR=${new_config_dir:-$CONFIG_DIR}
        configure_advanced
        ;;
    7)
        read -rp "Docker directory [$DOCKER_DIR]: " new_docker_dir
        DOCKER_DIR=${new_docker_dir:-$DOCKER_DIR}
        configure_advanced
        ;;
    8)
        read -rp "WordPress table prefix [$WP_TABLE_PREFIX]: " new_wp_table_prefix
        WP_TABLE_PREFIX=${new_wp_table_prefix:-$WP_TABLE_PREFIX}
        configure_advanced
        ;;
    9)
        read -rp "WordPress debug (true/false) [$WP_DEBUG]: " new_wp_debug
        WP_DEBUG=${new_wp_debug:-$WP_DEBUG}
        configure_advanced
        ;;
    10)
        read -rp "Production Docker network [$DOCKER_PROD_NETWORK]: " new_docker_prod_network
        DOCKER_PROD_NETWORK=${new_docker_prod_network:-$DOCKER_PROD_NETWORK}
        configure_advanced
        ;;
    11)
        save_config
        return
        ;;
    *)
        log_warning "Invalid choice: $choice"
        configure_advanced
        ;;
    esac
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
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'; frame-ancestors 'self';" always;
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

  $WP_CONTAINER:
    container_name: $WP_CONTAINER
    image: $WP_UNIT_TESTING_IMAGE
    restart: unless-stopped
    volumes:
      - $DATA_DIR/site:/var/www/html
      - $CONFIG_DIR/php:/usr/local/etc/php/conf.d
      # For plugins and themes under development
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
      - $WP_CONTAINER

  $WP_CLI_CONTAINER:
    container_name: $WP_CLI_CONTAINER
    image: wordpress:cli
    user: "\${USER_ID}:\${GROUP_ID}"
    volumes:
      - $DATA_DIR/site:/var/www/html
      - ./scripts:/scripts
    environment:
      WORDPRESS_DB_HOST: $DB_CONTAINER:3306
      WORDPRESS_DB_NAME: \${MYSQL_DATABASE}
      WORDPRESS_DB_USER: \${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PASSWORD}
    depends_on:
      - $WP_CONTAINER
    command: tail -f /dev/null

  $REDIS_CONTAINER:
    container_name: $REDIS_CONTAINER
    image: redis:7.2-alpine
    restart: unless-stopped
    volumes:
      - $DATA_DIR/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  $NGINX_CONTAINER:
    image: $NGINX_IMAGE
    container_name: $NGINX_CONTAINER
    restart: unless-stopped
    volumes:
      - $CONFIG_DIR/nginx:/etc/nginx/conf.d
      - $CONFIG_DIR/nginx/includes:/etc/nginx/my_include_files
      - $DATA_DIR/site:/var/www/html
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
      - $WP_CONTAINER

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

  $REDIS_CONTAINER:
    container_name: $REDIS_CONTAINER
    image: redis:7.2.5-alpine
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

# Simplified menu handling
show_menu() {
    clear
    local options=(
        "Configure project settings"
        "Configure advanced settings"
        "Generate .env file"
        "Generate nginx.conf file"
        "Generate PHP configs"
        "Generate development docker-compose.yml file"
        "Generate production docker-compose.yml file"
        "Docker operations menu"
        "WordPress CLI menu"
        "Remote sync operations menu"
        "Remote database sync menu"
        "Generate WP-CLI aliases file"
        "List all docker networks"
        "Create docker network"
        "Create required directories"
        "Check requirements"
        "Exit"
    )

    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       WordPress Docker Environment      ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo "Select one or more options (e.g., '1', '1-3', or '1 3 5')"

    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i + 1)) "${options[i]}"
    done

    echo -e "${BLUE}==========================================${NC}"
    read -rp "Enter your choice(s): " selection

    if [[ -z "$selection" ]]; then
        log_warning "No selection made."
        return 1
    fi

    # Process selection
    local selected=()

    # Parse the selection (handles ranges and individual selections)
    for choice in $selection; do
        if [[ "$choice" =~ ^[0-9]+-[0-9]+$ ]]; then
            # Range selection
            local start=${choice%-*}
            local end=${choice#*-}
            for ((i = start; i <= end; i++)); do
                selected+=($i)
            done
        elif [[ "$choice" =~ ^[0-9]+$ ]]; then
            # Individual selection
            selected+=($choice)
        fi
    done

    # Execute selected options
    for choice in "${selected[@]}"; do
        case $choice in
        1)
            configure_project
            ;;
        2)
            configure_advanced
            ;;
        3)
            generate_configs "env"
            ;;
        4)
            generate_configs "nginx"
            ;;
        5)
            generate_configs "php"
            ;;
        6)
            generate_configs "docker-dev"
            ;;
        7)
            generate_configs "docker-prod"
            ;;
        8)
            docker_menu
            ;;
        9)
            wpcli_menu
            ;;
        10)
            remote_sync_menu
            ;;
        11)
            remote_db_sync_menu
            ;;
        12)
            mkdir -p ~/.wp-cli
            cat <<EOF >~/.wp-cli/config.yml
@$PROJECT_NAME:
  ssh: ''
  path: /var/www/html
EOF
            log_success "WP-CLI aliases file generated!"
            ;;
        13)
            clear
            log_info "Docker Networks:"
            docker network ls
            read -p "Press Enter to continue..." enter_key
            ;;
        14)
            createDockerNetwork
            ;;
        15)
            create_directories
            ;;
        16)
            check_requirements
            ;;
        17)
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
    clear
    local options=(
        "Sync plugins from remote server"
        "Sync themes from remote server"
        "Sync uploads from remote server"
        "Sync all content from remote server"
        "Custom sync operation"
        "Back to main menu"
    )

    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}         Remote Sync Operations          ${NC}"
    echo -e "${BLUE}==========================================${NC}"

    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i + 1)) "${options[i]}"
    done

    echo -e "${BLUE}==========================================${NC}"
    read -rp "Enter your choice: " selection

    case $selection in
    1)
        read -p "Remote host (default: gcloud): " remote_host
        read -p "Remote path (default: ~/web/example.com): " remote_path
        handleRemoteSync "plugins" "${remote_host:-gcloud}" "${remote_path:-~/web/example.com}"
        ;;
    2)
        read -p "Remote host (default: gcloud): " remote_host
        read -p "Remote path (default: ~/web/example.com): " remote_path
        handleRemoteSync "themes" "${remote_host:-gcloud}" "${remote_path:-~/web/example.com}"
        ;;
    3)
        read -p "Remote host (default: gcloud): " remote_host
        read -p "Remote path (default: ~/web/example.com): " remote_path
        handleRemoteSync "uploads" "${remote_host:-gcloud}" "${remote_path:-~/web/example.com}"
        ;;
    4)
        read -p "Remote host (default: gcloud): " remote_host
        read -p "Remote path (default: ~/web/example.com): " remote_path
        handleRemoteSync "all" "${remote_host:-gcloud}" "${remote_path:-~/web/example.com}"
        ;;
    5)
        read -p "Remote host (default: gcloud): " remote_host
        read -p "Remote path: " remote_custom_path
        read -p "Local path: " local_custom_path
        if [[ -z "$remote_custom_path" || -z "$local_custom_path" ]]; then
            log_error "Both remote and local paths are required!"
        else
            handleRemoteSync "custom" "${remote_host:-gcloud}" "$remote_custom_path" "$local_custom_path"
        fi
        ;;
    6)
        return
        ;;
    *)
        log_warning "Invalid option: $selection"
        remote_sync_menu
        ;;
    esac
}

# Docker management submenu
docker_menu() {
    clear
    local options=(
        "Build and start containers"
        "Stop containers"
        "Start containers"
        "Restart containers"
        "Remove containers"
        "View logs"
        "Access container shell"
        "Back to main menu"
    )

    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}         Docker Management Menu          ${NC}"
    echo -e "${BLUE}==========================================${NC}"

    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i + 1)) "${options[i]}"
    done

    echo -e "${BLUE}==========================================${NC}"
    read -rp "Enter your choice: " selection

    case $selection in
    1)
        handleDocker "build"
        ;;
    2)
        handleDocker "stop"
        ;;
    3)
        handleDocker "start"
        ;;
    4)
        handleDocker "restart"
        ;;
    5)
        handleDocker "remove"
        ;;
    6)
        read -rp "Enter container name (wp, db, nginx, redis, vite): " container
        handleDocker "logs" "$container"
        ;;
    7)
        read -rp "Enter container name (wp, db, nginx, redis, vite, wpcli): " container
        handleDocker "shell" "$container"
        ;;
    8)
        return
        ;;
    *)
        log_warning "Invalid option: $selection"
        docker_menu
        ;;
    esac
}

# WP-CLI submenu
wpcli_menu() {
    clear
    local options=(
        "Install WordPress"
        "Create user"
        "Install plugin"
        "Install theme"
        "Enable debugging"
        "Disable debugging"
        "Run custom WP-CLI command"
        "Back to main menu"
    )

    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}         WP-CLI Management Menu          ${NC}"
    echo -e "${BLUE}==========================================${NC}"

    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i + 1)) "${options[i]}"
    done

    echo -e "${BLUE}==========================================${NC}"
    read -rp "Enter your choice: " selection

    case $selection in
    1)
        handleWpCli "install"
        ;;
    2)
        read -rp "Enter username: " username
        read -rp "Enter email: " email
        read -rp "Enter role (default: subscriber): " role
        read -rp "Enter password (default: password): " password
        handleWpCli "create-user" "$username" "$email" "$role" "$password"
        ;;
    3)
        read -rp "Enter plugin name: " plugin
        handleWpCli "install-plugin" "$plugin"
        ;;
    4)
        read -rp "Enter theme name: " theme
        handleWpCli "install-theme" "$theme"
        ;;
    5)
        handleWpCli "debug-on"
        ;;
    6)
        handleWpCli "debug-off"
        ;;
    7)
        read -rp "Enter custom WP-CLI command: " command
        handleWpCli "custom" "$command"
        ;;
    8)
        return
        ;;
    *)
        log_warning "Invalid option: $selection"
        wpcli_menu
        ;;
    esac
}

# Remote database sync submenu
remote_db_sync_menu() {
    clear
    local options=(
        "Pull database from remote server and update local database"
        "Push database to remote server and update remote database"
        "Search and replace domain in database"
        "Export database"
        "Import database"
        "Back to main menu"
    )

    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       Remote Database Operations        ${NC}"
    echo -e "${BLUE}==========================================${NC}"

    for i in "${!options[@]}"; do
        printf "%3d) %s\n" $((i + 1)) "${options[i]}"
    done

    echo -e "${BLUE}==========================================${NC}"
    read -rp "Enter your choice: " selection

    case $selection in
    1)
        log_info "Pulling database from remote server..."
        log_warning "This action will overwrite your local database entirely with the remote database!"
        read -p "Continue? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            log_info "Database pull cancelled."
            return
        fi
        read -p "Remote SSH host (default: $REMOTE_SSH_HOST): " ssh_host
        read -p "Remote DB container (default: $REMOTE_DB_CONTAINER): " db_container
        read -p "Remote DB user (default: $REMOTE_DB_USER): " db_user
        read -p "Remote DB password (default: $REMOTE_DB_PASSWORD): " db_pass
        read -p "Remote DB name (default: $REMOTE_DB_NAME): " db_name
        
        ssh_host=${ssh_host:-$REMOTE_SSH_HOST}
        db_container=${db_container:-$REMOTE_DB_CONTAINER}
        db_user=${db_user:-$REMOTE_DB_USER}
        db_pass=${db_pass:-$REMOTE_DB_PASSWORD}
        db_name=${db_name:-$REMOTE_DB_NAME}
        
        log_info "Creating backup of remote database..."
        ssh $ssh_host "docker exec $db_container mysqldump -u$db_user -p$db_pass $db_name" > dump.sql
        
        log_info "Importing database to local server..."
        docker exec -i $DB_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < dump.sql
        
        log_info "Updating URLs in database..."
        docker exec $WP_CLI_CONTAINER wp search-replace "$REMOTE_DOMAIN" "$LOCAL_DOMAIN" --all-tables
        
        log_success "Database pull complete!"
        ;;
    2)
        log_info "Pushing database to remote server..."
        log_warning "This action will overwrite your remote database entirely with the local database!"
        read -p "Continue? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            log_info "Database push cancelled."
            return
        fi
        read -p "Remote SSH host (default: $REMOTE_SSH_HOST): " ssh_host
        read -p "Remote DB container (default: $REMOTE_DB_CONTAINER): " db_container
        read -p "Remote DB user (default: $REMOTE_DB_USER): " db_user
        read -p "Remote DB password (default: $REMOTE_DB_PASSWORD): " db_pass
        read -p "Remote DB name (default: $REMOTE_DB_NAME): " db_name
        
        ssh_host=${ssh_host:-$REMOTE_SSH_HOST}
        db_container=${db_container:-$REMOTE_DB_CONTAINER}
        db_user=${db_user:-$REMOTE_DB_USER}
        db_pass=${db_pass:-$REMOTE_DB_PASSWORD}
        db_name=${db_name:-$REMOTE_DB_NAME}
        
        log_info "Updating URLs in database from $LOCAL_DOMAIN to $REMOTE_DOMAIN..."
        docker exec $WP_CLI_CONTAINER wp search-replace "$LOCAL_DOMAIN" "$REMOTE_DOMAIN" --all-tables
        
        log_info "Creating backup of local database with updated URLs..."
        docker exec $DB_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > dump.sql
        
        log_info "Transferring and importing database to remote server..."
        cat dump.sql | ssh $ssh_host "docker exec -i $db_container mysql -u$db_user -p$db_pass $db_name"
        
        log_info "Reverting URLs back in local database from $REMOTE_DOMAIN to $LOCAL_DOMAIN..."
        docker exec $WP_CLI_CONTAINER wp search-replace "$REMOTE_DOMAIN" "$LOCAL_DOMAIN" --all-tables
        
        log_success "Database push complete!"
        ;;
    3)
        log_info "Search and replace in database..."
        read -p "Search string: " search_str
        read -p "Replace string: " replace_str
        
        if [[ -z "$search_str" || -z "$replace_str" ]]; then
            log_error "Both search and replace strings are required!"
        else
            docker exec $WP_CLI_CONTAINER wp search-replace "$search_str" "$replace_str" --all-tables
            log_success "Search and replace complete!"
        fi
        ;;
    4)
        log_info "Exporting database..."
        read -p "Output filename (default: ${PROJECT_NAME}_db_backup.sql): " filename
        filename=${filename:-"${PROJECT_NAME}_db_backup.sql"}
        
        docker exec $DB_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$filename"
        log_success "Database exported to $filename!"
        ;;
    5)
        log_info "Importing database..."
        read -p "Input filename: " filename
        
        if [[ ! -f "$filename" ]]; then
            log_error "File not found: $filename"
        else
            docker exec -i $DB_CONTAINER mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < "$filename"
            log_success "Database imported from $filename!"
        fi
        ;;
    6)
        return
        ;;
    *)
        log_warning "Invalid option: $selection"
        remote_db_sync_menu
        ;;
    esac
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
            read -r name value <<< "$setting"
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
            read -r name value <<< "$setting"
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

    # Keep showing menu until user exits
    while true; do
        show_menu
        read -p "Press Enter to continue..." enter_key
    done
}

# Start the script
main
