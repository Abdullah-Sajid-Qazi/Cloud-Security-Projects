# Project – Secure AWS VPC using Infrastructure as Code (Terraform)

## Overview

This project demonstrates the design and implementation of a **production-grade, security-first AWS VPC** using **Infrastructure as Code (Terraform)**.

Rather than focusing on individual AWS services, the goal of this project is to show how a secure network foundation is designed: how exposure is controlled, how traffic is constrained, and how visibility is built in from the start. All infrastructure is defined as code so that intent is explicit, reviewable, and reproducible.



## Architecture Summary

The VPC uses the CIDR block **10.0.0.0/16** and spans **two Availability Zones** for resilience and fault isolation. Within each AZ, the network is deliberately segmented into three tiers:

* **Public subnets** for internet-facing components
* **Private application subnets** for workloads that require outbound access but should not be reachable from the internet
* **Isolated data subnets** for sensitive resources that must never have internet connectivity

This tiered model reduces blast radius and ensures that only components with a clear justification are exposed.



## Subnet Design

| Tier            | Subnets              | CIDR Blocks                  | Internet Access     |
| --------------- | -------------------- | ---------------------------- | ------------------- |
| Public          | Public A, Public B   | 10.0.1.0/24, 10.0.2.0/24     | Yes (IGW)           |
| Private (App)   | Private A, Private B | 10.0.10.0/24, 10.0.20.0/24   | Outbound only (NAT) |
| Data (Isolated) | Data A, Data B       | 10.0.100.0/24, 10.0.200.0/24 | None                |

The data tier has **no route to the internet**, by design.



## Network Segmentation and Routing

Network segmentation is enforced primarily through routing. Public subnets are the only subnets associated with an Internet Gateway, making them the sole entry point from the internet. Private application subnets have no inbound internet routes and rely on **AZ-local NAT Gateways** for controlled outbound access. This allows workloads to reach external dependencies without becoming internet-reachable themselves.

The data tier is intentionally isolated. Its route tables contain only local VPC routes, with no paths to an Internet Gateway or NAT Gateway. Even in the event of a workload compromise, this design prevents direct data exfiltration over the internet.

Routing is treated as a first-class security control rather than a connectivity afterthought.



## Availability and Fault Isolation

Outbound internet access for private subnets is provided through **one NAT Gateway per Availability Zone**. Each private subnet routes to the NAT Gateway in its own AZ, avoiding cross-AZ dependencies and hidden single points of failure.

This design ensures predictable behavior during AZ-level disruptions and mirrors how production environments are typically architected.



## Traffic Control and Least Privilege

Traffic between tiers is tightly controlled using **least-privilege Security Groups**. Access is defined using **security-group-to-security-group references**, rather than broad CIDR-based rules, to make intent explicit and minimize lateral movement.

The resulting traffic flow is simple and defensible:

* Internet traffic terminates at the public tier
* Only approved traffic is forwarded to the application tier
* The data tier is reachable solely from the application tier on explicitly required ports

Anything not explicitly allowed is denied by default.



## Defense in Depth

While Security Groups provide fine-grained control at the resource level, **Network ACLs** are used as subnet-level guardrails. These stateless controls provide an additional layer of protection, enabling coarse restrictions and emergency subnet-wide blocking if required.

Together, routing, Security Groups, and Network ACLs form a layered defense model where no single control is relied upon exclusively.



## Visibility and Observability

To ensure traffic can be audited and investigated, **VPC Flow Logs** are enabled at the VPC level and delivered to **CloudWatch Logs**. This provides visibility into both accepted and rejected traffic across all tiers.

In a larger environment, this visibility layer can be extended to centralized logging, long-term storage, and security analytics platforms without changing the underlying network design.



## Private Access to AWS Services

The architecture avoids sending AWS service traffic over the public internet by using **VPC Endpoints**. A gateway endpoint is used for Amazon S3, while interface endpoints enable private connectivity to services such as CloudWatch Logs.

This allows private and isolated workloads to interact with required AWS services without introducing new internet exposure or relying on NAT for internal AWS traffic.



## Infrastructure as Code Approach

All resources in this project are provisioned using Terraform. There are no manual configuration steps required in the AWS console. This approach ensures:

* Consistent and repeatable deployments
* Clear dependency ordering
* Easier review of security-relevant changes
* Safe teardown and recreation of the environment

Terraform serves as the single source of truth for the entire network.



## Extensibility

The VPC is designed to support future growth without compromising security. Additional application or data subnets can be added per AZ, new services can be integrated through VPC Endpoints, and inspection or logging capabilities can be expanded centrally.

Because the architecture’s intent is encoded directly in infrastructure definitions, future changes are easier to reason about and less likely to introduce accidental exposure.



## Cleanup

After validation and documentation, the environment can be safely removed using Terraform:

```bash
terraform destroy
```

Post-destroy verification ensures that no network resources, gateways, or endpoints remain.
## Key Takeaways

This project demonstrates how secure cloud networking is achieved through intentional design rather than default configurations. By combining segmentation, controlled routing, least-privilege access, and built-in visibility, the VPC provides a strong foundation for secure workloads while remaining flexible and reproducible through Infrastructure as Code.
