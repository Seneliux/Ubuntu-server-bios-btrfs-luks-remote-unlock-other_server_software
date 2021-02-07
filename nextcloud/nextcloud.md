# Nextcloud with collabora online server
Copy newest URL from here https://nextcloud.com/install/#instructions-server

cd /var/www/html/$YOUR_domain
wget https://download.nextcloud.com/server/releases/nextcloud-20.0.7.zip
unzip nextcloud*
chown -R www-data:www-data /var/www/html


Add to nginx:  
```properties
location /.well-known {
        # The following 6 rules are borrowed from `.htaccess`

        rewrite ^/\.well-known/host-meta\.json  /nextcloud/public.php?service=host-meta-json    last;
        rewrite ^/\.well-known/host-meta        /nextcloud/public.php?service=host-meta         last;
        rewrite ^/\.well-known/webfinger        /nextcloud/public.php?service=webfinger         last;
        rewrite ^/\.well-known/nodeinfo         /nextcloud/public.php?service=nodeinfo          last;

        location = /.well-known/carddav   { return 301 /nextcloud/remote.php/dav/; }
        location = /.well-known/caldav    { return 301 /nextcloud/remote.php/dav/; }

        try_files $uri $uri/ =404;
    }

 location ^~ /nextcloud {
        access_log /var/log/nginx/nextcloud.access custom;
        error_log /var/log/nginx/nextcloud.error warn;

# set max upload size
        client_max_body_size 512M;
        fastcgi_buffers 64 4K;

        # Enable gzip but do not remove ETag headers
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject applicati>

        # Pagespeed is not supported by Nextcloud, so if your server is built
        # with the `ngx_pagespeed` module, uncomment this line to disable it.
        #pagespeed off;

        # HTTP response headers borrowed from Nextcloud `.htaccess`
        add_header Referrer-Policy                      "no-referrer"   always;
        add_header X-Content-Type-Options               "nosniff"       always;
        add_header X-Download-Options                   "noopen"        always;
        add_header X-Frame-Options                      "SAMEORIGIN"    always;
        add_header X-Permitted-Cross-Domain-Policies    "none"          always;
        add_header X-Robots-Tag                         "none"          always;
        add_header X-XSS-Protection                     "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";

        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;
     # Specify how to handle directories -- specifying `/nextcloud/index.php$request_uri`
        # here as the fallback means that Nginx always exhibits the desired behaviour
        # when a client requests a path that corresponds to a directory that exists
        # on the server. In particular, if that directory contains an index.php file,
        # that file is correctly served; if it doesn't, then the request is passed to
        # the front-end controller. This consistent behaviour means that we don't need
        # to specify custom rules for certain paths (e.g. images and other assets,
        # `/updater`, `/ocm-provider`, `/ocs-provider`), and thus
        # `try_files $uri $uri/ /nextcloud/index.php$request_uri`
        # always provides the desired behaviour.
        index index.php index.html /nextcloud/index.php$request_uri;

        # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
        location = /nextcloud {
            if ( $http_user_agent ~ ^DavClnt ) {
                return 302 /nextcloud/remote.php/webdav/$is_args$args;
            }
        }
        # Rules borrowed from `.htaccess` to hide certain paths from clients
        location ~ ^/nextcloud/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)    { return 404; }
        location ~ ^/nextcloud/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

     # Ensure this block, which passes PHP files to the PHP process, is above the blocks
        # which handle static assets (as seen below). If this block is not declared first,
        # then Nginx will encounter an infinite rewriting loop when it prepends
        # `/nextcloud/index.php` to the URI, resulting in a HTTP 500 error response.
        location ~ \.php(?:$|/) {
            fastcgi_split_path_info ^(.+?\.php)(/.*)$;
            set $path_info $fastcgi_path_info;

            try_files $fastcgi_script_name =404;

            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $path_info;
            fastcgi_param HTTPS on;

            fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
            fastcgi_param front_controller_active true;     # Enable pretty urls
            fastcgi_pass php-handler;

            fastcgi_intercept_errors on;
            fastcgi_request_buffering off;
        }
        location ~ \.(?:css|js|svg|gif)$ {
            try_files $uri /nextcloud/index.php$request_uri;
            expires 6M;         # Cache-Control policy borrowed from `.htaccess`
            access_log off;     # Optional: Don't log access to assets
        }

        location ~ \.woff2?$ {
            try_files $uri /nextcloud/index.php$request_uri;
            expires 7d;         # Cache-Control policy borrowed from `.htaccess`
            access_log off;     # Optional: Don't log access to assets
        }

        location /nextcloud {
            try_files $uri $uri/ /nextcloud/index.php$request_uri;
        }
}

  # static files
    location ^~ /loleaflet {
        proxy_pass http://127.0.0.1:9979;
        proxy_set_header Host $http_host;
    }

    # WOPI discovery URL
    location ^~ /hosting/discovery {
        proxy_pass http://127.0.0.1:9979;
        proxy_set_header Host $http_host;
    }

    # Capabilities
    location ^~ /hosting/capabilities {
        proxy_pass http://127.0.0.1:9979;
        proxy_set_header Host $http_host;
    }

    # main websocket
    location ~ ^/lool/(.*)/ws$ {
        proxy_pass http://$YOUR_DOMAIN:9979;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }

    # download, presentation and image upload
    location ~ ^/lool {
        proxy_pass http://127.0.0.1:9979;
        proxy_set_header Host $http_host;
    }

    # Admin Console websocket
    location ^~ /lool/adminws {
        proxy_pass http://127.0.0.1:9979;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }
```

1. Create postgresql user and database for nextcloud:
using pgadmin4 web interface or manually.  
CREATE ROLE $NEXTCLOUD_USER WITH LOGIN PASSWORD '$password';  
CREATE DATABASE $NEXTCLOUD_DATABASE OWNER  $NEXTCLOUD_USER;

edit /etc/php/7.4/fpm/pool.d/www.conf by UNcommenting these lines:  
;env[HOSTNAME] = $HOSTNAME  
;env[PATH] = /usr/local/bin:/usr/bin:/bin  
;env[TMP] = /tmp  
;env[TMPDIR] = /tmp  
;env[TEMP] = /tmp  

edit /etc/php/7.4/fpm/php.ini  , change value to 512M  
memory_limit = 512M

service php7.4-fpm restart

cd /var/www/html/$HOST/nextcloud
Note occ command - not all configs are possible from gui, or changes of the configs can be made from terminal by running occ command as user www-data:  
sudo -u www-data php occ db:add-missing-indices


Memory cache:
https://markus-blog.de/index.php/2018/05/30/how-to-install-apcu-object-cache-in-php7-and-integrate-in-nextcloud/

apt install -y php-intl php-bcmath php-bmp php-imagick

From https://www.collaboraoffice.com/code/linux-packages/  with a little modification:

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0C54D189F4BA284D
sudo echo 'deb https://www.collaboraoffice.com/repos/CollaboraOnline/CODE-ubuntu2004 ./' >> /etc/apt/sources.list.d/code.list



cron background jobs
Set in Basic settings cron.  
crontab -u www-data -e
add line:
*/5  *  *  *  * php -f /var/www/html/$YOUR_DOMAIN/nextcloud/cron.php



loolconfig set ssl.enable false  
loolconfig set ssl.termination true  
loolconfig set net.proto ipv4  
loolconfig set storage.wopi.host $nextcloud.example.com  
 systemctl restart loolwsd
 
 TO change port from the default 9980 to 9979, append to line --port=9979
ExecStart=/usr/bin/loolwsd --version --o:sys_template_path=/opt/lool/systemplate --o:child_root_path=/opt/lool/child-roots --o:file_server_root_path=/usr/share/loolwsd --port=9979

 systemctl edit --full  loolwsd
systemctl restart loolwsd
