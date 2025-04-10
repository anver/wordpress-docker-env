# WordPress Docker Development Environment

A comprehensive Docker-based WordPress development environment designed for developers. This setup includes tools and configurations to streamline WordPress development, debugging, and deployment.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Available Features](#available-features)
  - [Project Configuration](#project-configuration)
  - [Docker Management](#docker-management)
  - [WordPress Management](#wordpress-management)
  - [Remote Operations](#remote-operations)
  - [Proxy Container Management](#proxy-container-management)
  - [Hosts File Management](#hosts-file-management)
- [Development Tools](#development-tools)
  - [Plugins and Themes Development](#plugins-and-themes-development)
  - [WP-CLI Usage](#wp-cli-usage)
  - [Debugging with Xdebug](#debugging-with-xdebug)
- [SSL Certificate Generation](#ssl-certificate-generation)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- **WordPress with PHP 8.4**: Latest PHP version for modern development.
- **MariaDB/MySQL**: Reliable database support.
- **Redis**: Object caching for performance optimization.
- **Nginx**: High-performance web server.
- **Xdebug**: Debugging support for IDEs.
- **WP-CLI**: Command-line interface for WordPress management.
- **Vite**: Frontend development with hot module replacement.
- **Remote Sync**: Sync plugins, themes, uploads, and databases.
- **SSL Support**: Generate local SSL certificates with `mkcert`.

## Requirements

- Docker and Docker Compose
- Git
- Bash (Linux/macOS) or WSL (Windows)

## Quick Start

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <repository-url>
   cd allword.local
   ```

2. Run the setup script:
   ```bash
   ./run.sh
   ```

3. Follow the interactive menu to configure your environment:
   - Configure project settings (domain, database credentials, etc.)
   - Check requirements
   - Create required directories
   - Generate configuration files
   - Create Docker network
   - Build and start containers

4. Access your WordPress site at the configured domain (default: http://wordpress.local).

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

## Available Features

### Project Configuration
- Set custom project name, domain, and database settings.
- Configure Docker networks and container names.
- Enable WordPress debugging options.
- Save and load configuration files.

### Docker Management
- Build, start, stop, restart containers.
- View container logs.
- Access container shells.
- Remove containers.

### WordPress Management
- Install WordPress.
- Create users.
- Install plugins and themes.
- Enable/disable debugging.
- Run custom WP-CLI commands.

### Remote Operations
- Sync plugins, themes, and uploads from remote servers.
- Pull/push databases between environments.
- Search and replace operations in the database.
- Import/export databases.

### Proxy Container Management
- Start, stop, and remove the proxy container.
- Check proxy container status.
- Automatically configure ports and certificates.

### Hosts File Management
- Add or remove domains from the `/etc/hosts` file.
- Check if a domain exists in the hosts file.

## Development Tools

### Plugins and Themes Development

The script mounts directories from `/media/anver/work/plugins` and `/media/anver/work/themes` to the WordPress container, making them available as:
- Plugins: `/var/www/html/wp-content/plugins-dev`
- Themes: `/var/www/html/wp-content/themes-dev`

### WP-CLI Usage

The environment includes WP-CLI for WordPress management. Use the WP-CLI menu in the script or directly access the container:

```bash
# Using the script menu
./run.sh
# Then select "WordPress CLI menu"

# Or run direct commands
docker exec wp-cli wp <command>
```

### Debugging with Xdebug

Xdebug is configured and ready to use with common IDEs. The configuration includes:

- Debug mode enabled.
- Remote connections to `host.docker.internal`.
- Debug port `9003`.
- IDE Key: `VSCODE`.

## SSL Certificate Generation

The script includes an option to generate SSL certificates using `mkcert`. This ensures secure HTTPS connections for your local development environment.

1. Ensure `mkcert` is installed on your system.
2. Select the "Generate certificates using mkcert" option in the script:
   ```bash
   ./run.sh
   ```
3. The certificates will be saved in the directory specified by the `PROXY_CERTS_DIR` variable (default: `~/certs`).

## Production Deployment

For production deployment:

1. Configure your environment using the script's advanced settings.
2. Generate the production docker-compose file.
3. Deploy using:
   ```bash
   docker compose -f docker-compose.prod.yaml up -d
   ```

## Configuration

The script generates a configuration file (`wordpress-docker.conf`) that stores all your settings. You can edit this file directly or use the configuration menus in the script.

## Troubleshooting

### Common Issues and Solutions

1. **Docker Containers Not Starting**
   - Ensure Docker is running on your system.
   - Check for port conflicts (e.g., ports 80 or 443 in use) and stop any services using these ports.
   - Run `docker compose logs` to view error messages.

2. **Domain Not Resolving**
   - Verify the domain is added to your `/etc/hosts` file.
   - Use the "Manage hosts file" option in the script to add the domain.

3. **Database Connection Errors**
   - Check the database credentials in the `.env` file.
   - Ensure the database container is running: `docker ps`.

4. **Xdebug Not Working**
   - Verify the IDE is configured to listen on port `9003`.
   - Ensure `host.docker.internal` is accessible from the container.

5. **Permission Issues**
   - Ensure the script is not run as root.
   - Verify file and directory permissions match your user ID and group ID.

6. **SSL Certificate Issues**
   - Ensure `mkcert` is installed and configured.
   - Regenerate certificates using the "Generate certificates using mkcert" option in the script.

7. **Remote Sync Fails**
   - Verify SSH access to the remote server.
   - Check the remote path and permissions.

### Getting Help

If you encounter issues not covered here, consider:
- Reviewing the logs using `docker compose logs`.
- Checking the official documentation for Docker, WordPress, or related tools.
- Opening an issue in the project repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
