# RxRevu Service Standards

## Rails Services

<!--TOC max2 -->

### Getting Started

#### Create yours rails app
1. Run a docker container for ruby:
    ```bash
    > docker run -it -v $(pwd):/usr/src/app ruby:2.5.5 bash
    ```
2. Within the docker shell:
    ```bash
    > cd /usr/src/app
    > gem install rails -v 5.2.4.2
    > rails new <service_name> --skip-test --skip-bundle --database postgresql --no-action-cable --skip-coffee --api
    > exit
    ```

3. Create `Dockerfile` and add the following:

    [Dockerfile.example](./Dockerfile.example)

4. Create `docker-compose.yml` and add the following:

    [docker-compose.yml.example](./docker-compose.yml.example)

### Logging

We use `rails_semantic_logger`.

#### Setup

1. Add the following to `Gemfile` and bundle (within docker):
    ```ruby
    gem "rails_semantic_logger"
    ```

2. Add this to the bottom of your `application.rb` (be sure to change service name):
    ```ruby
    unless Rails.env.test?
      config.log_tags = {
        request_id: :request_id,
        remote_ip: :remote_ip,
      }

      config.rails_semantic_logger.add_file_appender = false # turn off default appender

      payload_filter = lambda do |log|
        return false if log.name == "HealthCheck::HealthCheckController"

        if log.payload.present?
          return false if log.payload[:path] == "/health_check"
        end

        return true
      end

      if ENV["LOG_LEVEL"].present?
        config.log_level = ENV["LOG_LEVEL"].downcase.strip.to_sym
      end

      config.semantic_logger.add_appender(
        application: "<ServiceName>", # replace with service name
        file_name: "log/<service_name>.log", # replace with service name
        formatter: :json,
        filter: payload_filter,
        level: config.log_level
      )
      config.semantic_logger.add_appender(
        application: "<ServiceName>",
        io: STDOUT,
        formatter: :json,
        filter: payload_filter,
        level: config.log_level
      )
    end
    ```

3. Celebrate

### APM

We use the ELK stack.

#### Setup

1. Add the following to `Gemfile` and bundle (within docker):
    ```ruby
    gem "elastic-apm"
    ```

2. Create `config/elastic_apm.yml` and add the following (be sure to change service name):

    [elastic_apm.yml.example](./elastic_apm.yml.example)

3. Create `.env/development/apm` and add the following:

    [apm](./env/development/apm)

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

    Git clone this project: [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)

2. Create elk network

    ```bash
    > docker network create docker-elk_elk
    ```

3. Run docker-elk
    ```bash
    > docker-compose -f docker-compose.yml -f extensions/apm-server/apm-server-compose.yml up
    ```

4. Celebrate

#### Starting Kibana

1. Navigate to [http://localhost:5601](http://localhost:5601)
2. (F) Username: elastic
3. (F) Password: changeme
4. (B) Add APM
5. APM Server
    1. (T) macOS
    2. (B) Check APM Server status
6. APM Agents
    1. (T) Ruby on Rails
    2. (B) Check agent status
    3. (B) Load Kibana objects
    4. (B) Launch APM
7. (L) FdbService // replace with service name
8. Celebrate

### Metrics (Prometheus)

We use `prometheus_exporter`.

#### Setup

1. Add the following to `Gemfile` and bundle (within docker):
    ```ruby
    gem "prometheus_exporter", "0.4.16"
    ```

2. Create `config/docker/initialize_rails.sh` and add:

    [initialize_rails.sh](./initialize_rails.sh)

3. Make the following changes to your service(s) in `docker-compose.yml`:
    ```yml
    ports:
      ...
      - "8080:9394"
    ```

4. Create `config/initializers/0_prometheus.rb` and add:

    [0_prometheus.rb](./0_prometheus.rb)

5. In `Dockerfile`, replace the `CMD`line with:
    ```
    # Prometheus Exporter
    RUN mkdir -p /opt/<service_name>
    COPY config/docker/initialize_rails.sh /opt/<service_name>/initialize.sh
    RUN chmod +x /opt/<service_name>/initialize.sh

    CMD ["/opt/<service_name>/initialize.sh"]
    ```
6. Navigate to [http://localhost:8080/metrics](http://localhost:8080/metrics) to verify it's working

7. Celebrate

### Metrics (Filebeat)

TBD

### Metrics (Metricbeat)

TBD

### Health Checks

We use `health_check`.

#### Setup

1. Add the following to `Gemfile` and bundle (within docker):
    ```ruby
    gem "health_check", "3.0.0"
    ```

2. Create `config/initializers/health_check.rb` and add:

    [health_check.rb](./health_check.rb)

3. Add the following to `config/routes.rb`
    ```ruby
    ...
    health_check_routes
    ...
    ```

4. Navigate to [http://localhost:3000/health_check](http://localhost:3000/health_check) to verify it's working

---

### Configuration Management

TBD

### Secrets Management

TBD

### Security

TBD

### Containerization (Docker)

TBD

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

---

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
   echo "* Loading schema"
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


