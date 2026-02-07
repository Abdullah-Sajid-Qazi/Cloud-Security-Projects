# Cloud Security Portfolio ☁️ 🛡️

[![Terraform](https://img.shields.io/badge/Infrastructure%20as%20Code-Terraform-623CE4)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-aws)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/DevSecOps-GitHub%20Actions-2088FF)](https://github.com/features/actions)

---

## 📖 About This Repository

This monorepo serves as a centralized collection of my work in **Cloud Security**, **DevSecOps**, and **Infrastructure as Code (IaC)**.

Rather than isolated scripts, this repository documents my journey in building production-grade security architectures. The projects contained here simulate real-world enterprise environments, focusing on the trade-offs between security, usability, and cost.

**Core Philosophy:**
* **Shift Left:** Security is integrated into the design and build phases, not bolted on afterwards.
* **Immutable Infrastructure:** All resources are defined in code (Terraform) to prevent configuration drift.
* **Defense in Depth:** Controls are layered across identity, network, and application levels.

---

## 🏗️ Technical Scope

This repository allows me to experiment with and demonstrate competency in the following domains:

| Domain | Focus Areas |
| :--- | :--- |
| **Identity & Access (IAM)** | Least Privilege, Role Assumption, Cross-Account Architecture, SCPs. |
| **Network Security** | VPC Design, Segmentation, Traffic Inspection, WAF implementation. |
| **DevSecOps** | CI/CD Pipelines, Secret Scanning, SAST/DAST integration, Policy as Code. |
| **Compliance & GRC** | Automated Auditing, Cloud Benchmarks (CIS), Remediation planning. |
| **Visibility & Response** | Centralized Logging, SIEM integration, Automated Incident Response. |

---

## 🛠️ Technology Stack

The projects in this repository are built using the following tools and technologies:

* **Cloud Provider:** Amazon Web Services (AWS)
* **Infrastructure as Code:** Terraform, CloudFormation
* **Containerization:** Docker, ECS
* **Scripting:** Python (Boto3), Bash
* **Security Tools:** Prowler, Checkov, Trivy, OWASP ZAP

---

## 📂 Repository Structure

The projects are organized by architectural domain. Each directory contains its own documentation, architecture diagrams, and deployment instructions.
