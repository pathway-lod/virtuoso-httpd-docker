# Base: official OpenLink Virtuoso Open Source 7 image
FROM openlink/virtuoso-opensource-7:latest

LABEL maintainer="elena.delpup@wur.nl"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install Apache + Git (for SNORQL) + helper tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apache2 \
        git \
        crudini \
        openssl && \
    rm -rf /var/lib/apt/lists/*

# Avoid the noisy "could not reliably determine the server name" warning
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && \
    a2enconf servername

# Enable Apache proxy modules and our SPARQL proxy config
RUN a2enmod proxy proxy_http && \
    a2enmod headers && \
    echo "Include /etc/apache2/conf-available/sparql-proxy.conf" >> /etc/apache2/apache2.conf

COPY ./apache-sparql-proxy.conf /etc/apache2/conf-available/sparql-proxy.conf
RUN a2enconf sparql-proxy

# 2) Clone Snorql UI
#    We keep the old /usr/local/apache2/htdocs path (for script.sh),
#    and make Apache's DocumentRoot (/var/www/html) point there too.
RUN mkdir -p /usr/local/apache2 && \
    rm -rf /usr/local/apache2/htdocs && \
    git clone https://github.com/pathway-lod/Snorql-UI.git /usr/local/apache2/htdocs && \
    rm -rf /var/www/html && \
    ln -s /usr/local/apache2/htdocs /var/www/html

# 3) Copy your helper scripts (NO custom virtuoso.ini here!)
COPY ./script.sh     /script.sh
COPY ./load.sh       /load.sh
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod 755 /script.sh /load.sh /entrypoint.sh

# 4) Virtuoso configuration via environment variables
#    /database is the canonical DB dir in the openlink image.
#    We allow /database and /import for the bulk loader.
ENV VIRT_Parameters_DirsAllowed="., /opt/virtuoso-opensource/vad, /database, /import, /tmp"

# (Optional but nice) set a default DBA password for dev
ENV DBA_PASSWORD=dba

# Apache runtime vars (Debian layout)
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid

# 5) Ports: Virtuoso HTTP (8890), SQL (1111), Apache (80, 443)
EXPOSE 8890 1111 80 443

# 6) Volumes: Virtuoso data, Snorql UI (optional override)
VOLUME /database

WORKDIR /database

# 7) Custom entrypoint that starts Virtuoso and Apache
ENTRYPOINT ["/entrypoint.sh"]