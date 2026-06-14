# Naming & Tagging Strategy

## Naming Convention
Format:
<resource>-<env>-<region>

Example:
vnet-spoke-prod-weu

---

## Tagging Requirements

All resources must include:

- Environment
- Owner
- Project
- CostCenter
- Criticality
- ManagedBy
- Workload

---

## Enforcement Strategy
Tags and naming conventions will be enforced using:
- Azure Policy (deny non-compliant deployments)
- CI/CD validation pipelines
- Go compliance checker CLI tool