# Project – Secure AWS VPC using Infrastructure as Code (Terraform)

## Overview

This project demonstrates how to design and implement a **production‑grade, security‑first AWS VPC** using **Infrastructure as Code (Terraform)**.

The goal is not just to create networking resources, but to show **how a real cloud security engineer thinks about isolation, blast radius, routing, and visibility**. Every decision is intentional, documented, and reproducible.

The environment is designed to be **short‑lived** (build → validate → destroy) so it remains cost‑effective while still following correct production patterns.

---

## Core Security Goals

This VPC architecture is designed to mitigate:

* Accidental public exposure of internal workloads
* Lateral movement in flat networks
* Uncontrolled outbound internet access
* Single‑AZ egress failures
* Lack of visibility during incident response

Security is enforced at **multiple layers**, not a single control.

---

## High‑Level Architecture

* One VPC (`10.0.0.0/16`)
* Two Availability Zones
* Three subnet tiers per AZ:

  * **Public** (internet‑facing)
  * **Private Application** (no inbound internet)
  * **Data / Isolated** (no internet access at all)

All infrastructure is provisioned using Terraform. The AWS Console is used only for verification and evidence collection.

---

## Subnet Design

| Tier            | Subnets              | CIDR Blocks                  | Internet Access     |
| --------------- | -------------------- | ---------------------------- | ------------------- |
| Public          | Public A, Public B   | 10.0.1.0/24, 10.0.2.0/24     | Yes (IGW)           |
| Private (App)   | Private A, Private B | 10.0.10.0/24, 10.0.20.0/24   | Outbound only (NAT) |
| Data (Isolated) | Data A, Data B       | 10.0.100.0/24, 10.0.200.0/24 | None                |

The data tier has **no route to the internet**, by design.

---

## Routing Strategy

### Public Tier

* Default route (`0.0.0.0/0`) → Internet Gateway
* Hosts internet‑facing components only

### Private Application Tier

* Default route (`0.0.0.0/0`) → AZ‑local NAT Gateway
* No inbound internet access
* No cross‑AZ egress dependency

### Data Tier

* Local VPC routing only
* No Internet Gateway
* No NAT Gateway

Routing itself is treated as a **security control**, not just connectivity.

---

## NAT Gateways (High Availability)

* One NAT Gateway per Availability Zone
* Each private subnet routes to its local NAT

This avoids:

* Single points of failure
* Cross‑AZ traffic during outages

Although this increases cost slightly, it reflects correct production design and remains affordable for short‑lived labs.

---

## Security Groups (Primary Enforcement)

Security Groups are implemented using **SG‑to‑SG references only**.

### Traffic Model

* Internet → ALB (HTTPS)
* ALB → Application tier
* Application tier → Data tier

No CIDR‑based trust is used between tiers. Each tier can only communicate with the tier directly above or below it.

---

## Network ACLs (Guardrails)

Network ACLs are used as **subnet‑level guardrails**, not primary controls.

They provide:

* Coarse‑grained protection
* Emergency subnet‑wide blocking capability
* Defense‑in‑depth alongside security groups

Each tier has its own NACL aligned with its purpose.

---

## Visibility: VPC Flow Logs

VPC Flow Logs are enabled at the **VPC level** and delivered to **CloudWatch Logs**.

This provides:

* Visibility into accepted and rejected traffic
* Evidence for investigations
* The ability to answer "what talked to what" during incidents

Security without telemetry is incomplete. Flow Logs close that gap.

---

## VPC Endpoints (Private AWS Access)

To prevent AWS service traffic from traversing the public internet:

* **S3 Gateway Endpoint** is used for private and data tiers
* **CloudWatch Logs Interface Endpoint** is used for private subnets

This allows isolated resources to access required AWS services **without NAT or internet exposure**.

---

## Infrastructure as Code Principles

This project follows strict IaC discipline:

* No manual console configuration
* Explicit resource definitions
* Clear dependency ordering
* Reproducible builds
* Safe teardown using `terraform destroy`

Terraform is the source of truth.

---

## Cost Awareness

The environment is intended to run for only a few hours:

* Multi‑AZ NAT Gateways
* Flow Logs with short retention
* Immediate teardown after validation

This keeps total cost under a few dollars while still demonstrating real‑world architecture.

---

## Cleanup

After validation and evidence collection:

```bash
terraform destroy
```

Post‑destroy checks:

* NAT Gateways removed
* Elastic IPs released
* VPC Endpoints deleted
* No running resources left behind

Cleanup is treated as part of the project, not an afterthought.

---

## Key Takeaways

* Routing decisions directly impact security
* Isolation must be enforced at multiple layers
* Visibility is as important as prevention
* Infrastructure as Code enables review, consistency, and safe destruction
This project reflects how production VPCs are **designed, reviewed, and defended** in real cloud environments.

