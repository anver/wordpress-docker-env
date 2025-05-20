#!/bin/sh
set -e

# - `adduser`: Command to add a new user to the system
# - `-G www-data`: Sets the supplementary group for the new user to "www-data"
# - `-g www-data`: Sets the primary group for the new user to "www-data"
# - `-s /bin/sh`: Specifies the login shell for the new user as sh
# - `-D`: Creates a system user without a password (disabled password login)
# - `www-data`: The username being created

# This command is commonly used in containerized environments to create a non-root user with specific permissions for running web server processes. The "www-data" user is a conventional name for the user that web servers (like Apache or Nginx) run as, helping to improve security by not running web services as root.

# The `-D` flag specifically indicates this is Alpine Linux's version of `adduser`, which is more minimalist than other Linux distributions.

# Remove user if exists
if getent passwd www-data >/dev/null 2>&1; then
    deluser www-data >/dev/null 2>&1 || true
fi

# Remove group if exists
if getent group www-data >/dev/null 2>&1; then
    delgroup www-data >/dev/null 2>&1 || true
fi

# Create with specified UID/GID, defaults to 1000 if not provided
GROUP_ID=${GROUP_ID:-1000}
USER_ID=${USER_ID:-1000}

# Add group and user
addgroup -g "$GROUP_ID" www-data
adduser -u "$USER_ID" -G www-data -g www-data -s /bin/sh -D www-data

echo "www-data user configured with UID=$USER_ID, GID=$GROUP_ID"
