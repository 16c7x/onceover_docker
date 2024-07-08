# specifying the platform here allows builds to work
# correctly on Apple Silicon machines
FROM --platform=amd64 ruby:3.1.0-slim-buster as base

ARG VCS_REF
ARG GH_USER=16c7x

LABEL org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/${GH_USER}/onceover_docker"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -y locales \
  && sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \
  && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y apt-utils \
  && apt-get update -qq \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends curl libxml2-dev libxslt1-dev g++ gcc git gnupg2 make openssh-client ruby-dev wget zlib1g-dev libldap-2.4-2 libldap-common libssl1.1 openssl cmake \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* 

RUN ln -s /bin/mkdir /usr/bin/mkdir

# Prep for non-root user
RUN groupadd --gid 1001 puppetdev \
  && useradd --uid 1001 --gid puppetdev --create-home puppetdev

RUN gem install bundler -v 2.4.22 \
  && chown -R puppetdev:puppetdev /usr/local/bundle \
  && mkdir /setup \
  && chown -R puppetdev:puppetdev /setup \
  && mkdir /repo \
  && chown -R puppetdev:puppetdev /repo

# Switch to a non-root user for everything below here
USER puppetdev

# Install dependent gems
WORKDIR /setup
ADD Gemfile* /setup/
#COPY Rakefile /Rakefile

RUN bundle config set system 'true' \
  && bundle config set jobs 3 \
  && bundle install \
  && rm -f /home/puppetdev/.bundle/config \
  && rm -rf /usr/local/bundle/gems/puppet-7.*.0/spec

WORKDIR /repo

FROM base AS rootless

FROM base AS main
USER root
