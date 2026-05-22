FROM ruby:3.4-bookworm

ARG NODE_VERSION=22

# Node.js + yarn
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# システム依存パッケージ
RUN apt-get update && apt-get install -y \
    postgresql-client \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Doppler CLI
RUN curl -Ls --tlsv1.2 --proto "=https" --retry 3 https://cli.doppler.com/install.sh | sh

# Rails
RUN gem install rails bundler

WORKDIR /workspaces/anisonar
