# WordPress Docker Development Environment

A comprehensive Docker-based WordPress development environment with support for:

- WordPress with PHP 8.4
- MariaDB 
- Redis for object caching
- Nginx webserver
- Xdebug for debugging
- WP-CLI for WordPress management
- Vite for frontend development

## Requirements

- Docker and Docker Compose
- Git
- Bash (Linux/macOS) or WSL (Windows)

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com//wordpress-docker-env.git
   cd wordpress-docker-env
   ```

2. Configure your environment:
   ```bash
   # Edit the config.sh file
   nano config.sh
   ```

3. Run the installer:
   ```bash
   ./install.sh
   ```

4. Select the following options from the menu:
   - Check requirements
   - Generate .env file
   - Create required directories
   - Generate PHP configs
   - Generate nginx.conf file
   - Generate development docker-compose.yml file
   - Create docker network
   - Run docker commands (select Build)

5. Access your WordPress site at http://allword.local (or the domain you configured)

## Directory Structure

```
.
├── config/                 # Configuration files
│   ├── nginx/              # Nginx configuration
│   └── php/                # PHP configuration
├── data/                   # Persistent data
│   ├── mysql/              # Database files
│   ├── redis/              # Redis data
│   └── site/               # WordPress files
├── docker/                 # Custom Docker images
│   └── wp/                 # WordPress image
├── scripts/                # Helper scripts
├── .env                    # Environment variables
├── config.sh               # Configuration variables
├── docker-compose.yaml     # Development environment
├── docker-compose.prod.yaml # Production environment
├── install.sh              # Installation script
├── wp-cli.sh               # WP-CLI wrapper script
└── README.md               # Documentation
```

## Plugins and Themes Development

The `plugins` and `themes` directories are symbolic links to the `/media/anver/work/plugins` and `/media/anver/work/themes` directories, respectively. This allows you to easily manage your plugins and themes in a single location.

### Working with Plugins and Themes

Your plugins and themes are available inside the WordPress container at:
- Plugins: `/var/www/html/wp-content/plugins-dev`
- Themes: `/var/www/html/wp-content/themes-dev`

To work on a plugin or theme:

1. Create a symbolic link from your development folder to the WordPress plugins/themes directory
   ```bash
   # For plugins
   ln -s /path/to/your/plugin data/site/wp-content/plugins/your-plugin

   # For themes
   ln -s /path/to/your/theme data/site/wp-content/themes/your-theme
   ```

2. Activate the plugin or theme in WordPress admin

## WP-CLI Usage

The environment includes WP-CLI for WordPress management. Use the included wrapper script:

```bash
./wp-cli.sh <command>

# Examples:
./wp-cli.sh core version
./wp-cli.sh plugin list
./wp-cli.sh user create john john@example.com --role=author
```

## Debugging with Xdebug

Xdebug is configured and ready to use with VS Code. Make sure to:

1. Install the PHP Debug extension in VS Code
2. Use the provided launch configuration in .vscode/launch.json
3. Set breakpoints in your code
4. Start the debugger in VS Code
5. Access your site to trigger the breakpoints

## Production Deployment

For production deployment:

1. Configure your environment:
   ```bash
   # Edit the config.sh file with production values
   nano config.sh
   ```

2. Generate production files:
   ```bash
   ./install.sh
   ```

3. Select "Generate production docker-compose.yml file" from the menu

4. Deploy using:
   ```bash
   docker-compose -f docker-compose.prod.yaml up -d
   ```

## Backing Up and Restoring

Use the provided scripts to backup and restore your WordPress site:

```bash
# Backup database
./scripts/backup-db.sh

# Restore database
./scripts/restore-db.sh backups/db-backup-20230101123456.sql
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
