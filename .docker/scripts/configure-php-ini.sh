#!/bin/sh
echo 'memory_limit = 1024M' > /usr/local/etc/php/conf.d/wordpress.ini
    echo 'max_execution_time = 300' >> /usr/local/etc/php/conf.d/wordpress.ini
    echo 'upload_max_filesize = 64M' >> /usr/local/etc/php/conf.d/wordpress.ini
    echo 'post_max_size = 64M' >> /usr/local/etc/php/conf.d/wordpress.ini
    echo 'date.timezone = "UTC"' >> /usr/local/etc/php/conf.d/wordpress.ini