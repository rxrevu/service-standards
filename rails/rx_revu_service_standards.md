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

3. Create '.env/development/apm' and add the following:
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
    Git clone this project: [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)

2. Run docker-elk
    ```yml
    docker-compose up -d
    ```

3. Celebrate

#### Starting Kibana

1. Navigate to http://localhost:5601
2. (B) Add APM
3. APM Server
    1. (T) macOS
    2. (B) Check APM Server status
4. APM Agents
    1. (T) Ruby on Rails
    2. (B) Check agent status
    3. (B) Load Kibana objects
    4. (B) Launch APM
5. (L) FdbService // replace with service name
6. Celebrate

### Metrics

We use `prometheus_exporter`.

#### Setup

1. Add this to your Gemfile:
    ```ruby
    gem "prometheus_exporter", "0.4.16"
    ```

2. Add the following to `config/docker/intialize_rails.sh`
    ```sh
    #!/bin/sh
    set -e
    cd /home/app/rxcheck
    exec /sbin/setuser app /usr/bin/bundle exec prometheus_exporter
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

2. TBD

#### Security Vulnerability Scanner

We use `brakeman`.

##### Setup

1. Add this to your Gemfile:
    ```ruby
    gem 'brakeman', '~> 4.8'
    ```

2. TBD

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

2. TBD

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

1. Dockerfile
2. docker-compose.yml

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

#### CodePipeline / CodeDeploy

TBD