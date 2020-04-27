# RxRevu Service Standards

1. Observability
    1. Logging
    2. APM
        1. ELK
    3. Metrics
        1. Prometheus
        2. Metricbeat
        3. Filebeat
        4. Grafana
2. Security
    1. In Transit
    2. At Rest
    3. Application
        1. API / Bearer Tokens
        2. JWT?
3. Traceability
4. Monitoring / Alerting
    1. Health Checks
        1. Common Endpoint? (e.g. `/health_check`)
        2. Checks
            1. Database
            2. Migrations
            3. Cache
            4. Other?
    2. Auto-Scaling?
    3. Pingdom
5. Deployment
    1. CI / CD
        1. CodeBuild
        2. CodePipeline / CodeDeploy
    2. Miscellaneous
        1. Drone?
6. Infrastructure
    1. Containerization (Docker)
        1. Container Scanning?
        2. Multi-Stage Docker Files?
        3. Golden Image?
    2. Configuration Management
        1. Param Store
        2. AppConfig?
        3. Config Endpoint? (e.g. `/config` or `/version`)
    3. Secrets Management
        1. Param Store
        2. Hashicorp's Vault?
    4. Terraform
        1. Style
        2. Naming Conventions
        3. Static v. Dynamic
        4. Environment Specific
        5. Tags
            1. PHI
            2. Classification
            3. Environment
            4. Terraform
            5. Application?
    5. Miscellaneous
        1. Fargate v. EC2?
        2. Hashicorp's Consul?
        3. Kubernetes / EKR?
6. Source Control
    1. GitHub
        1. Webhooks
        2. Branch Rules
        3. Personal Access Tokens
7. Reliability
    1. Retries
    2. Fallbacks
    3. Timeouts
    4. Circuit Breakers
    5. Load Balancing
    6. Rate Limits
8. Application Level Concerns
    1. Tests
        1. Test Coverage
    2. Static Code Analysis
    3. Security Vulnerability Scanner
    4. Library Vulnerability Scanner
    5. Documentation
        1. Swagger/Open API
        2. gRPC
            3. Protobuf
    6. Caching
