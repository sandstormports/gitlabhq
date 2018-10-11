# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Content: Dockerfile for GitLab on Sandstorm
# Author: Jan Jambor, XWare GmbH
# Author URI: https://xwr.ch
# Date: 10.10.2018
#
# https://about.gitlab.com/installation/#debian
# https://packages.gitlab.com/gitlab/gitlab-ce?filter=debs
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

FROM bitnami/minideb:stretch
ENV SANDSTORM_VERSION=239

# Install and configure the necessary dependencies
RUN apt-get update -q \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    curl \
    openssh-server \
    ca-certificates \
    binutils

# Install Postfix
#RUN apt-get install -yq --no-install-recommends postfix

# Download the sandstorm distribution, and extract sandstorm-http-bridge from it:
RUN curl -O https://dl.sandstorm.io/sandstorm-${SANDSTORM_VERSION}.tar.xz
RUN tar -x sandstorm-${SANDSTORM_VERSION}/bin/sandstorm-http-bridge -f sandstorm-${SANDSTORM_VERSION}.tar.xz
RUN cp sandstorm-${SANDSTORM_VERSION}/bin/sandstorm-http-bridge ./
# Stripping the binary reduces its size by about 10x:
RUN strip sandstorm-http-bridge

# Add the GitLab package repository and install the package
RUN curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

# Install the GitLab package
RUN apt-get install -yq --no-install-recommends gitlab-ce

# Copy config file
ADD gitlab.rb /etc/gitlab/gitlab.rb

# Expose web & ssh
EXPOSE 443 80 22

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]
