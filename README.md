# WordPress Docker Development Environment

A comprehensive Docker-based WordPress development environment with support for:

- WordPress with PHP 8.4
- MariaDB/MySQL database
- Redis for object caching
- Nginx webserver
- Xdebug for debugging
- WP-CLI for WordPress management
- Vite for frontend development
- Remote sync capabilities
- Database migration tools

## Requirements

- Docker and Docker Compose
- Git
- Bash (Linux/macOS) or WSL (Windows)

## Quick Start

1. Run the setup script:
   ```bash
   ./run.sh
   ```

2. Follow the interactive menu to configure your environment:
   - Configure project settings (domain, database credentials, etc.)
   - Check requirements
   - Create required directories
   - Generate configuration files
   - Create Docker network
   - Build and start containers

3. Access your WordPress site at the domain you configured (default: http://wordpress.local)

## Available Features

### Project Configuration
- Set custom project name, domain, and database settings
- Configure Docker networks and container names
- Set WordPress debugging options
- Advanced configuration for Docker images and directories

### Docker Management
- Build, start, stop, restart containers
- View container logs
- Access container shells
- Remove containers

### WordPress Management
- Install WordPress
- Create users
- Install plugins and themes
- Enable/disable debugging
- Run custom WP-CLI commands

### Remote Operations
- Sync plugins, themes, and uploads from remote servers
- Pull/push databases between environments
- Search and replace operations in database
- Import/export databases

## Directory Structure

```
.
├── config/                 # Configuration files
│   ├── nginx/              # Nginx configuration
│   │   └── includes/       # Additional Nginx configurations
│   └── php/                # PHP configuration
├── data/                   # Persistent data
│   ├── mysql/              # Database files
│   ├── redis/              # Redis data
│   └── site/               # WordPress files
├── docker-compose.yaml     # Development environment
├── docker-compose.prod.yaml # Production environment
├── wordpress-docker.conf   # Configuration variables
├── run.sh                  # Main script for environment management
└── README.md               # Documentation
```

## Plugins and Themes Development

The script mounts directories from `/media/anver/work/plugins` and `/media/anver/work/themes` to the WordPress container, making them available as:
- Plugins: `/var/www/html/wp-content/plugins-dev`
- Themes: `/var/www/html/wp-content/themes-dev`

## WP-CLI Usage

The environment includes WP-CLI for WordPress management. Use the WP-CLI menu in the script or directly access the container:

```bash
# Using the script menu
./run.sh
# Then select "WordPress CLI menu"

# Or run direct commands
docker exec wp-cli wp <command>
```

## Remote Sync Operations

The script provides several options to sync data from remote servers:

1. Use the "Remote sync operations menu" to:
   - Sync plugins from remote server
   - Sync themes from remote server
   - Sync uploads from remote server
   - Sync all content from remote server
   - Perform custom sync operations

2. Use the "Remote database sync menu" to:
   - Pull database from remote server
   - Push database to remote server
   - Search and replace domain names or other strings
   - Export/import databases

## Debugging with Xdebug

Xdebug is configured and ready to use with common IDEs. The configuration includes:

- Debug mode enabled
- Remote connections to host.docker.internal
- Debug port 9003
- IDE Key: "VSCODE"

## Production Deployment

For production deployment:

1. Configure your environment using the script's advanced settings
2. Generate the production docker-compose file
3. Deploy using:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d
   ```

## Configuration

The script generates a configuration file (`wordpress-docker.conf`) that stores all your settings. You can edit this file directly or use the configuration menus in the script.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
