# Azure Landing Zone - Overview

## Goal
Build a secure enterprise Azure foundation with governance, networking, and compliance automation.

## Core Architecture

- Hub VNet (central network)
- Spoke VNets (Dev/Prod/Test)
- VNet Peering (hub ↔ spokes)
- Azure Firewall (central traffic control)
- NSGs (subnet-level security)
- Virtual Machines(Dev/Prod/Test)

## Governance Layer

- Azure Policy (compliance rules)
- RBAC (role-based access control)
- Tag enforcement (cost + ownership tracking)

## Security & Secrets

- Key Vault for secrets management
- Restricted public access by default

## Monitoring

- Log Analytics Workspace
- Diagnostic logs for all resources
## Automation Tools

- Terraform + Bicep (infrastructure)
- PowerShell (governance checks)
- Bash (network validation)
- Go CLI (compliance checker)

## Design Principle
Everything is code, everything is auditable, everything is enforceable.