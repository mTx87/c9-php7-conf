# Pull base image.
FROM ubuntu:16.04
MAINTAINER Nooke <nooke@nooke.eu>

# Install Supervisor.
RUN \
  apt-get update && \
  apt-get install -y supervisor && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf

# Define mountable directories.
VOLUME ["/etc/supervisor/conf.d"]

# ------------------------------------------------------------------------------
# Security changes
# - Determine runlevel and services at startup [BOOT-5180]
RUN update-rc.d supervisor defaults

# - Check the output of apt-cache policy manually to determine why output is empty [KRNL-5788]
RUN apt-get update | apt-get upgrade -y

# - Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc [AUTH-9262]
RUN apt-get install libpam-cracklib -y
RUN ln -s /lib/x86_64-linux-gnu/security/pam_cracklib.so /lib/security

# Define working directory.
WORKDIR /etc/supervisor/conf.d

# ------------------------------------------------------------------------------
# Install base
RUN apt-get update
RUN apt-get install -y build-essential g++ curl libssl-dev apache2-utils git libxml2-dev sshfs


# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs


# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/
WORKDIR /opt/
RUN git clone https://github.com/julianbrowne/apache-anywhere.git
COPY conf/apache apache-anywhere/bin/apache
COPY conf/httpd.conf apache-anywhere/config/httpd.conf
COPY conf/Apache.run /workspace/.c9/runners/Apache.run
RUN chmod +x -R apache-anywhere

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace
VOLUME /workspace

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list
RUN curl http://www.dotdeb.org/dotdeb.gpg | apt-key add -
RUN apt-get update
RUN apt-get install -y php7.0 php7.0-cli
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN apt-get install -y python-setuptools
RUN easy_install pip
RUN pip install -U pip
RUN pip install -U virtualenv
RUN virtualenv --python=python2 /workspace/.c9/python2
RUN source /workspace/.c9/python2/bin/activate
RUN apt-get install -y python-dev
RUN mkdir /tmp/codeintel
RUN pip download -d /tmp/codeintel codeintel==0.9.3
RUN cd /tmp/codeintel
RUN tar xf CodeIntel-0.9.3.tar.gz
RUN mv CodeIntel-0.9.3/SilverCity CodeIntel-0.9.3/silvercity
RUN tar czf CodeIntel-0.9.3.tar.gz CodeIntel-0.9.3
RUN pip install -U --no-index --find-links=/tmp/codeintel codeintel

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 80
EXPOSE 3000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
