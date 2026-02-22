In this lesson, we'll dive into **Cilium**, the Container Network Interface (CNI) solution used throughout this course. Developed by Isovalent, Cilium is available as an open source edition and a paid subscription. We'll focus on the open source version.

### CNCF Project and Adoption

Cilium is part of the Cloud Native Computing Foundation landscape. Originally released in 2015, it has seen rapid adoption (принятие, распространение) - boasting (хвастовство) nearly 20,000 stars on GitHub as of this recording.

### Unified Networking, Observability & Security

Cilium delivers a single platform for:

- Networking
- Observability
- Security

Additionally, Cilium can function as:

- A service mesh
- A load balancer between services
- An encryption provider

Its flexibility and advanced capabilities make it ideal for modern cloud-native deployments.

### How Cilium Works

At its core (по своей сути), Cilium leverages eBPF to implement a high-performance, Layer 3 network that is protocol-aware (которая учитывает протоколы) at Layer 7. It can replace kube-proxy and enforce network policies at Layers 3, 4, and 7.

<img src="image.png" width="900" height="400"><br>

By using eBPF, Cilium achieves features like bandwidth management and fine-grained policy enforcement without kernel modifications.

### eBPF Overview

**eBPF** (Extended Berkeley Packet Filter) is a Linux kernel technology that allows sandboxed (изолированным) programs to run safely in kernel space. Developers can inject custom logic at runtime - without adding kernel modules or changing kernel source code.

| Use Case | Description |
| ----------- | ----------- |
| High-performance networking | Packet processing directly in the kernel |
| Load balancing | Efficient traffic distribution |
| Security enforcement | Stateful firewalls and IDS (Intrusion Detection System) |
| Packet filtering | Fine-grained packet selection |
| Profiling & tracing | In-kernel observability and performance insights |

Intrusion Detection System - система обнаружения вторжений.

<img src="image-1.png" width="900" height="400"><br>

### Cilium Agent

On every Kubernetes node, a **Cilium agent** manages the eBPF programs that handle container networking, security policies, and observability hooks.

### Hubble: Observability & Security

Hubble is a distributed networking and security observability platform built on Cilium and eBPF. It provides visibility into:

- Pod-to-pod communications
- Service dependency maps
- Security events
- Multi-cluster traffic flows

**Warning**

Enabling Hubble in production requires careful consideration of resource usage and data retention policies.

### Advanced Network Policies

Cilium supports both Layer 3/4 and Layer 7 policies, using workload identities (идентификаторы рабочих нагрузок) derived (полученные) from Kubernetes labels instead of IP addresses:

| Layer | Controls | Protocols |
| ----------- | ----------- | ----------- |
| 3 & 4 | IP, CIDR, port-based allow/deny | TCP, UDP, ICMP |
| 7	| API-aware filtering and routing | HTTP, gRPC, Kafka |