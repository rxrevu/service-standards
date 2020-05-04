# Terraform Naming Standards

1. Prefer ALL CAPS for params/ENV vars
2. Prefer underscores in terraform names
3. Prefer hyphens for aws resources

## IAM Policies

Prefer data policy document over inline json for IAM policies

## Miscellaneous

### Container CPU/Memory

Prefer vars for things like:
  - containter_cpu
  - container_memory
