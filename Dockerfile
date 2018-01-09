# Pull base image
FROM kdelfour/supervisor-docker
MAINTAINER Sebastian 'Nooke' Tannert <nooke@nooke.eu>

# install base
RUN apt-get update
RUN apt-get install -y build-essential 

# add repos
RUN add-apt-repository -y ppa:ondrej/php
RUN add-apt-repository -y ppa:ondrej/apache2
RUN apt-get update

# install stuff
RUN apt-get install g++ curl software-properties-common libxml2-dev git apache2-utils libssl-dev sshfs

# install node.js
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y nodejs

# install cliud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# tweak standalone.js
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js

# add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# add volumes
RUN mkdir /workspace
VOLUME /workspace

# install apache + php
RUN apt-get update;apt-get install -y apache2 php libapache2-mod-php

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
