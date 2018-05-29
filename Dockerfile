# Pull base image.
FROM kdelfour/supervisor-docker
MAINTAINER Nooke <nooke@nooke.eu>

# install base
RUN apt-get update
RUN apt-get install -y build-essential g++ curl software-properties-common

# add repos
RUN add-apt-repository -y ppa:ondrej/php
RUN add-apt-repository -y ppa:ondrej/apache2
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C
RUN apt-get update

# Install stuff
RUN apt-get install -y libxml2-dev git apache2-utils libssl-dev sshfs

# install node
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs

# install cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# Install PHP7.2
RUN apt-get install -qq php7.2-fpm php7.2-cli php7.2-common php7.2-json php7.2-opcache php7.2-mysql php7.2-phpdbg \
php7.2-mbstring php7.2-gd php7.2-imap php7.2-ldap php7.2-pgsql php7.2-pspell php7.2-recode php7.2-tidy php7.2-dev \
php7.2-intl php7.2-gd php7.2-curl php7.2-zip php7.2-xml

# add volumes
RUN mkdir /workspace
VOLUME /workspace

# install apache + php
RUN apt-get update
RUN apt-get install -y apache2 php libapache2-mod-php

# apache php stuff
RUN apt-get install -y vim
RUN a2enmod headers; a2enmod dir; service apache2 stop

WORKDIR /opt/
RUN git clone https://github.com/julianbrowne/apache-anywhere.git
COPY conf/apache apache-anywhere/bin/apache
COPY conf/httpd.conf apache-anywhere/config/httpd.conf
COPY conf/Apache.run /workspace/.c9/runners/Apache.run
RUN chmod +x -R apache-anywhere

# add gulp
RUN npm install -g gulp

# add composer
RUN curl -sS https://getcomposer.org/install | sudo php -- --install-dir=/usr/local/bin --filename=composer

# clean up apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
         
# expose ports
EXPOSE 80
EXPOSE 3000

# start supervisor
CMD ["supervisord", "-c" "/etc/supervisor/supervisord.conf"]
