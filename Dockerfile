ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client vim && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . ./app

EXPOSE 3000
CMD ["/bin/sh"]
