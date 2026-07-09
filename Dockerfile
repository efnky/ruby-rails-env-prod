FROM ruby:3.3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

FROM ruby:3.3.11-slim
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/* && \
    groupadd -r rails && useradd -r -g rails -u 1001 rails
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app/vendor /app/vendor
COPY . .
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    mkdir -p tmp log storage && \
    chown -R rails:rails tmp log storage
EXPOSE 3000
USER 1001
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]