FROM ruby:2.6.5-alpine
LABEL maintainer="andre@trefle.io"
LABEL description="The trefle.io backend API docker image"

RUN apk update && apk upgrade && apk add \
  make cmake build-base coreutils libpq gcc g++ libc-dev linux-headers \
  imagemagick-dev imagemagick libgcrypt-dev postgresql-dev \
  libxml2 libxml2-dev libxml2-utils libxslt-dev \
  zlib-dev curl curl-dev ruby-dev \
  tzdata yaml yaml-dev bash git \
  nodejs yarn && \
  rm -rf /var/cache/apk/*

RUN gem install bundler

ENV RAILS_ROOT /app/
RUN mkdir /app
WORKDIR /app

ENV LANG C.UTF-8
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV PORT 3000

# VOLUME ["/tmp"]

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install --without development test -j4 --retry 3 --path vendor

ADD . /app
RUN mkdir -p /app/tmp/pids && \
  chmod -R 777 /app/tmp && \
  chmod 777 /app/bin/post-start

RUN bundle exec rails assets:precompile --trace --verbose
RUN rm -rf /app/node_modules storage /usr/local/share/.cache/yarn log/* *.md test kube frontend spec tmp/cache lib/assets spec && \
  rm -rf /var/cache/apk/* && \
  rm -rf /app/config/master.key

ARG SENTRY_RELEASE=untagged
ENV SENTRY_RELEASE=${SENTRY_RELEASE}
ENV APP_REVISION=${SENTRY_RELEASE}

ARG RAILS_MASTER_KEY=unset
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

EXPOSE 3000

ENTRYPOINT bundle exec rails server
