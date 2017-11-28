FROM ruby:2.4.1-alpine
COPY Gemfile /app/
COPY Gemfile.lock /app/

RUN apk --update add --virtual build-dependencies ruby-dev build-base && \
    gem install bundler --no-ri --no-rdoc && \
    cd /app ; bundle install --without development test && \
    apk del build-dependencies

COPY . /app

RUN chown -R nobody:nogroup /app

USER nobody

ENV RACK_ENV production
ENV APP_ENV production

EXPOSE 3000

WORKDIR /app

CMD ["bundle", "exec", "rackup", "-p", "3000", "/app/config.ru"]
