# RxRevu Service Standards

## Rails Services

<!--TOC max2 -->

### Logging

We use `rails_semantic_logger`.

#### Setup

1. Add this to your Gemfile:
    ```ruby
    gem "rails_semantic_logger"
    ```

2. Add this to your `application.rb`:
    ```ruby
    config.log_tags = {
      request_id: :request_id,
      remote_ip: :remote_ip,
    }

    config.rails_semantic_logger.add_file_appender = false # turn off default appender

    config.semantic_logger.add_appender(
      application: "FdbService", # replace with service name
      file_name: "log/fdb_service.log", # replace with service name
      formatter: :json,
    )
    ```

3. Celebrate

### APM

We use the ELK stack.

#### Setup

1. Add this to your Gemfile:
    ```ruby
    gem "elastic-apm"
    ```

2. Create `config/elastic_apm.yml` and add the following:
    ```yml
    server_url: <%= ENV["ELASTIC_APM_SERVER_URL"] %>
    secret_token: <%= ENV["ELASTIC_APM_SECRET_TOKEN"] %>
    active: <%= ENV.fetch("ELASTIC_APM_ACTIVE", "false") %>
    service_name: "FdbService" # replace with service name
    service_version: <%= ENV.fetch("SERVICE_VERSION", "unknown") %>
    ```

3. Create `.env/development/apm` and add the following:
    ```
    ELASTIC_APM_ACTIVE=true
    ELASTIC_APM_API_REQUEST_TIME=29s
    ELASTIC_APM_CAPTURE_BODY=off
    ELASTIC_APM_IGNORE_URL_PATTERNS=health_check
    ELASTIC_APM_METRICS_INTERVAL=10s
    ELASTIC_APM_SECRET_TOKEN=''
    ELASTIC_APM_SERVER_URL=http://apm-server:8200
    ELASTIC_APM_SOURCE_LINES_ERROR_APP_FRAMES=10
    ELASTIC_APM_SOURCE_LINES_ERROR_LIBRARY_FRAMES=5
    ELASTIC_APM_SOURCE_LINES_SPAN_APP_FRAMES=0
    ELASTIC_APM_SOURCE_LINES_SPAN_LIBRARY_FRAMES=0
    ELASTIC_APM_TRANSACTION_SAMPLE_RATE=0.2
    ELASTIC_APM_VERIFY_SERVER_CERT=false
    ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ELASTICSEARCH_PASSWORD=<get this from your friends>
    ELASTICSEARCH_USERNAME=<get this from your friends>
    ```

4. Make the following changes to your service(s) in `docker-compose.yml`:
    ```yml
    env_file:
      ...
      - .env/development/apm
    networks:
      ...
      - elk
    ```

5. Add the following network to `docker-compose.yml`:
    ```yml
    networks:
      ...
      elk:
        external:
          name: docker-elk_elk
    ```

6. Celebrate

#### Running Elk:

1. Clone docker-elk
    * Git clone this project: [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)
2. Create elk network
    `docker network create docker-elk_elk`
3. Run docker-elk
    ```yml
       docker-compose -f docker-compose.yml -f extensions/apm-server/apm-server-compose.yml up 
    ```

4. Celebrate

#### Starting Kibana

1. Navigate to http://localhost:5601
2. Login using the `ELASTICSEARCH_USERNAME` and `ELASTICSEARCH_PASSWORD` stored in 1Password under "RxRevu - Elk Vars"
3. (B) Add APM
4. APM Server
    1. (T) macOS
    2. (B) Check APM Server status
5. APM Agents
    1. (T) Ruby on Rails
    2. (B) Check agent status
    3. (B) Load Kibana objects
    4. (B) Launch APM
6. (L) FdbService // replace with service name
7. Celebrate

### Metrics

We use `prometheus_exporter`.

#### Setup

1. Add this to your Gemfile:
    ```ruby
    gem "prometheus_exporter", "0.4.16"
    ```

2. Add the following to `config/docker/initialize_rails.sh`
   ```sh
   #!/bin/sh
   set -e
   cd /usr/src/app
   bin/bundle exec prometheus_exporter &
   rm -f tmp/pids/server.pid
   bin/rails s -b 0.0.0.0
   ```

3. Make the following changes to your service(s) in `docker-compose.yml`:
    ```yml
    ports:
      ...
      - "8080:9394"
    ```

4. Add the following to `config/initializers/0_prometheus.rb`
    ```ruby
    unless Rails.env.test?
      require 'prometheus_exporter/instrumentation'
      require 'prometheus_exporter/middleware'
      require 'prometheus_exporter/client'

      client = PrometheusExporter::Client.new(
        custom_labels: {
          environment: Rails.env,
        },
      )
      client.register(:counter, "fdb_service", "Metadata for fdb_service").increment

      PrometheusExporter::Client.default = client
      Rails.application.middleware.unshift PrometheusExporter::Middleware

      Rails.application.config.after_initialize do
        require 'prometheus_exporter/instrumentation'

        PrometheusExporter::Instrumentation::ActiveRecord.start(
          custom_labels: {
            type: "web"
          },
          config_labels: [:database, :host]
        )

        PrometheusExporter::Instrumentation::Process.start(
          type: "web"
        )
      end
    end

    ```
5. Rebuild docker image: `docker-compose build`
6. Add the following to `Dockerfile`
    ```
    # Prometheus Exporter
    RUN mkdir -p /opt/fdb_service
    COPY config/docker/initialize_rails.sh /opt/fdb_service/initialize.sh
    RUN chmod +x /opt/fdb_service/initialize.sh
    CMD ["/opt/fdb_service/initialize.sh"]
    ```
7. Navigate to `localhost:8080/metrics` to verify it's working
8. Celebrate    

### Health Checks

We use `health_check`.

#### Setup

1. Add this to your Gemfile:
    ```ruby
    gem "health_check", "3.0.0"
    ```

2. Add the following to `config/initializers/health_check.rb`
    ```ruby
    HealthCheck.setup do |config|
      config.standard_checks = [ "database", "migrations"]
      config.full_checks = [ "database", "migrations"]
    end
    ```

3. Add the following to `config/routes.rb`
    ```ruby
    ...
    health_check_routes
    ...
    ```

4. Navigate to `localhost:3000/health_check` to verify it's working    

### Rails Standards

TBD

#### Tests

We use `rspec`.

##### Setup

1. Add this to your Gemfile:
    ```ruby
    group :development, :test do
      ...
      gem "rspec-rails", "~> 3.5", ">= 3.5.2"
      ...
    end
    ```

2. Bundle

3. Initialize rspec (replace with service name): `docker-compose run fdb bundle exec rails generate rspec:install`

#### Static Code Analysis

We use `rubocop`.

##### Setup

1. Add this to your Gemfile:
    ```ruby
    group :development, :test do
      ...
      gem "rubocop", require: false
      ...
    end
    ```
   
2. Create `.rubocop.yml` at the top level of your project:
    ```
    AllCops:
      TargetRubyVersion: 2.5.5
      Exclude:
        - spec/dummy/db/schema.rb
    
    Layout/LineLength:
      Max: 120
    
    Style/AndOr:
      Enabled: false
    
    Lint/ShadowingOuterLocalVariable:
      Enabled: false
    
    Style/Documentation:
      Enabled: false
    
    Style/FrozenStringLiteralComment:
      Enabled: false
    
    Style/StringLiterals:
      EnforcedStyle: double_quotes
    
    Style/TrailingCommaInArguments:
      EnforcedStyleForMultiline: comma
    
    Style/TrailingCommaInArrayLiteral:
      EnforcedStyleForMultiline: comma
    
    Style/TrailingCommaInHashLiteral:
      EnforcedStyleForMultiline: comma
    ```

3. Bundle

#### Security Vulnerability Scanner

We use `brakeman`.

##### Setup

1. Add this to your Gemfile:
    ```ruby
    gem 'brakeman', '~> 4.8'
    ```

2. Bundle

#### Gem Vulnerability Scanner

We use `bundle_audit`.

##### Setup

1. Add this to your Gemfile:
    ```ruby
    group :development, :test do
      ...
      gem "bundler-audit", "0.6.1"
      ...
    end
    ```

2. Bundle

#### Running tests

We use `test.sh` to wrap the above steps

##### Setup

1. Create `test.sh`:
   ```
   #!/usr/bin/env bash
   
   exit_code=0
   
   echo "****************************************"
   echo "** MyService                          **"
   echo "****************************************"
   
   echo ""
   echo "* Bundling"
   echo ""
   bundle | grep Installing
   
   echo ""
   echo "*** Running Brakeman Checks"
   echo "* Installing latest brakeman"
   
   output="$(bundle exec brakeman --quiet --exit-on-warn --exit-on-error --no-pager --ensure-latest 2>&1)"
   brakeman_exit_code=$?
   
   echo ""
   echo "************************************"
   if (($brakeman_exit_code)) ; then
     printf "\e[31m${output}\e[0m\n"
   else
     echo "${output}"
   fi
   echo "************************************"
   echo ""
   
   exit_code=$(($exit_code + $brakeman_exit_code))
   
   echo ""
   echo "*** Running Bundler-Audit Check"
   bundle exec bundle-audit check --update
   
   exit_code=$(($exit_code + $?))
   
   echo ""
   echo "*** Running Rubocop Checks"
   echo "* Bundling"
   bundle exec rubocop --config ./.rubocop.yml --fail-level W --display-only-fail-level-offenses
   
   exit_code=$(($exit_code + $?))
   
   echo ""
   echo "*** Running Specs"
   echo "* Clearing log directory"
   find . -name "*.log" | xargs rm -f
   echo "* Dropping database"
   RAILS_ENV=test bundle exec rake db:drop
   echo "* Creating database"
   RAILS_ENV=test bundle exec rake db:create
   echo "* Loading structure"
   RAILS_ENV=test bundle exec rake db:schema:load
   
   bundle exec rspec
   
   exit_code=$(($exit_code + $?))
   
   echo ""
   echo "************************************"
   if ((exit_code == 0)) ; then
     echo "TESTS SUCCEEDED"
   else
     echo "TESTS FAILED"
   fi
   echo "************************************"
   
   exit $exit_code
   ```   
2. Run `docker-compose run fdb ./test.sh`

#### Schema v. Structure

Prefer `schema`. It is the default with Rails and is database engine agnostic. However, there are times when `structure` is required. Here are a couple of known reasons to prefer `structure`:
- You need views.
- You need database specific extentions (e.g. `postgis` for `postgresql`)

### Configuration Management

TBD

### Secrets Management

TBD

### Security

TBD

### Containerization (Docker)

TBD

1. Dockerfile example:
   ```
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
     yarn
   
   COPY Gemfile* /usr/src/app/
   WORKDIR /usr/src/app
   ENV BUNDLE_PATH /gems
   RUN bundle install
   
   RUN echo "Prometheus Exporter setup"
   COPY . /usr/src/app/
   RUN mkdir -p /opt/fdb_service
   COPY config/docker/initialize_rails.sh /opt/fdb_service/initialize.sh
   RUN chmod +x /opt/fdb_service/initialize.sh
   CMD ["/opt/fdb_service/initialize.sh"]
   ```

2. docker-compose.yml example:
   ```
    version: '3'
    
    services:
      web:
        build: .
        ports:
          - "3000:3000"
          - "8080:9394"
        volumes:
          - .:/usr/src/app
          - gem_cache:/gems
        env_file:
          - .env/development/database
          - .env/development/web
          - .env/development/apm
        networks:
          - elk
    
      database:
        image: postgres
        env_file:
          - .env/development/database
        volumes:
          - db_data:/var/lib/postgresql/data
        networks:
          - elk
    
    volumes:
      db_data:
      gem_cache:
    
    networks:
      elk:
        external:
          name: docker-elk_elk
   ```

### Terraform

TBD

1. Setup Database
2. Setup Load Balancer
    1. Listener
    2. Target Group
3. Setup Service
    1. Task Definition

### CI / CD

TBD

#### CodeBuild

TBD
`buildspec.yml`

```
   version: 0.2
   
   phases:
     install:
       runtime-versions:
         ruby: 2.6
       commands:
         - export TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c -7)
         - echo $TAG
     pre_build:
       commands:
         - echo Logging in to Amazon ECR...
         - $(aws ecr get-login --region us-east-1 --no-include-email)
         - export ECR_REPO_PREFIX="566112438981.dkr.ecr.us-east-1.amazonaws.com/fdb_service"
     build:
       commands:
         - echo Build Stage started on `date`
         - echo Testing Source Code...
         - docker network create alt_curation
         - docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d fdb_database
         - docker-compose -f docker-compose.yml -f docker-compose.test.yml run --rm fdb bash -c "./test.sh"
         - docker-compose down
         - echo Building Docker Image...
         - docker build -t fdb_service_build .
     post_build:
       commands:
         - echo Pushing Docker Image...
         - docker tag fdb_service_build:latest $ECR_REPO_PREFIX:$TAG
         - docker push $ECR_REPO_PREFIX:$TAG
         - sed "s/\$TAG/${TAG}/" imagedefinitions_template.json > imagedefinitions.json
   artifacts:
     files:
       - ./imagedefinitions.json
       - ./appspec.yaml
```
`imagedefinitions_template.json`
```
   [
     {
       "name": "fdb_service",
       "imageUri": "566112438981.dkr.ecr.us-east-1.amazonaws.com/fdb_service:$TAG"
     }
   ]
```

#### CodePipeline / CodeDeploy

TBD
- terraform stuff
`docker-compose.test.yml`
```
  version: '3'
  
  services:
    fdb:
      env_file:
        - .env/test/database
        - .env/test/web
```
- create & commit .env/test/*
- create webhook 