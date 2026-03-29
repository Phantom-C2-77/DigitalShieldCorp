FROM php:8.2-apache

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl wget procps net-tools && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Create upload directory (writable but not listed)
RUN mkdir -p /var/www/html/assets/uploads && chmod 777 /var/www/html/assets/uploads

# Apache config — hide server version
RUN echo "ServerTokens Prod" >> /etc/apache2/conf-enabled/security.conf && \
    echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf

# .htaccess for uploads (allows PHP execution — the vulnerability)
RUN printf 'Options -Indexes\n' > /var/www/html/assets/uploads/.htaccess

# Basic auth for admin panel
RUN apt-get update && apt-get install -y apache2-utils && rm -rf /var/lib/apt/lists/* && \
    htpasswd -cb /etc/apache2/.htpasswd webadmin 'W3b@dm1n_2026!' && \
    printf '<Directory "/var/www/html/admin">\n  AuthType Basic\n  AuthName "Admin Panel"\n  AuthUserFile /etc/apache2/.htpasswd\n  Require valid-user\n</Directory>\n' > /etc/apache2/conf-enabled/admin-auth.conf

RUN mkdir -p /var/www/html/admin

COPY html/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
