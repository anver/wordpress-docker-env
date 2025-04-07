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
- Proxy container management
- Hosts file management

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
- Save and load configuration files

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

### Proxy Container Management
- Start, stop, and remove the proxy container
- Check proxy container status
- Automatically configure ports and certificates
- **Generate SSL certificates using mkcert**

### Hosts File Management
- Add or remove domains from the `/etc/hosts` file
- Check if a domain exists in the hosts file

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

## Proxy Container Management

The script includes options to manage a proxy container for handling multiple domains and SSL certificates:

1. Start the proxy container:
   ```bash
   ./run.sh
   # Select "Manage proxy container" -> "Run main proxy container"
   ```

2. Stop and remove the proxy container:
   ```bash
   ./run.sh
   # Select "Manage proxy container" -> "Stop and remove proxy container"
   ```

3. Check the proxy container status:
   ```bash
   ./run.sh
   # Select "Manage proxy container" -> "Check proxy container status"
   ```

## Debugging with Xdebug

Xdebug is configured and ready to use with common IDEs. The configuration includes:

- Debug mode enabled
- Remote connections to host.docker.internal
- Debug port 9003
- IDE Key: "VSCODE"

## Local Domain Setup

The environment can manage your `/etc/hosts` file to add or remove local domains:

1. Select the "Manage hosts file" option from the menu.
2. Choose to add, remove, or check domains in the hosts file.

## SSL Certificate Generation

The script includes an option to generate SSL certificates using `mkcert`. This ensures secure HTTPS connections for your local development environment.

1. Ensure `mkcert` is installed on your system. If installed via Homebrew, the script will attempt to update it automatically.
2. Select the "Generate certificates using mkcert" option from the menu:
   ```bash
   ./run.sh
   # Select "Generate certificates using mkcert"
   ```
3. The certificates will be saved in the directory specified by the `PROXY_CERTS_DIR` variable (default: `~/certs`).

If you encounter issues, refer to the "Troubleshooting" section for solutions.

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
   - Verify the IDE is configured to listen on port 9003.
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
