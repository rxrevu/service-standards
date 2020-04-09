FROM ruby:2.5.5
RUN echo 'alias be="bundle exec"' >> ~/.bashrc

LABEL maintainer="dev@rxrevu.com"

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  apt-transport-https

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  yarn \
  postgresql-client \
  jq \
  awscli

COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app
ENV BUNDLE_PATH /gems
RUN bundle install

COPY . /usr/src/app/
RUN chmod +x ./fdb_import.sh

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
