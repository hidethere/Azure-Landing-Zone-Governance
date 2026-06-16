# Azure Landing Zone Architecture

## Overview
This project implements an enterprise-grade Azure Landing Zone using a Hub-and-Spoke model. It provides centralized governance, networking, security, and observability for all workloads.

---

## Architecture Goals
- Centralized network control
- Secure workload isolation
- Policy-driven governance
- Full observability

---

## High-Level Design

- **Hub VNet**
  - Shared services
  - Azure Firewall
  - Log Analytics Workspace
  - Key Vault
  - Bastion Host

- **Spoke VNets(Dev/Prod/Test)**
  - Isolated workload environments
  - No direct internet exposure
  - Routed through hub
  - Virtual machines(Dev/Prod/Test)

---

## Flow of Traffic
Spokes → Hub → Firewall → Internet / Services

---

## Core Components
- Azure Policy (governance enforcement)
- RBAC (role-based access control)
- Terraform/Bicep (infrastructure as code)
- Monitoring via Azure Monitor + Log Analytics

---

## Design Principles
- Zero trust networking
- Least privilege access
- Infrastructure as Code only
- Centralized logging and monitoring