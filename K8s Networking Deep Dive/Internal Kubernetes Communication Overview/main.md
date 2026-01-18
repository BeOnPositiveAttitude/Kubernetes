In this lesson, we'll explore how pods communicate inside a Kubernetes cluster. We'll cover key patterns and tools - from the basic network model to advanced service meshes - so you can design reliable (надежные), secure, and scalable applications.

### Recap (краткое повторение): Kubernetes Network Model

Kubernetes enforces a flat, IP-per-pod network. The core principles are:

Unique Pod IP
Every Pod receives its own IP address.
Local Node Traffic
Pods on the same node communicate via localhost or the CNI bridge.
Cluster-wide Reachability
Pods on different nodes talk without NAT, thanks to the CNI (we’re using Cilium).
Note

We use Cilium with eBPF for high-performance routing, policy enforcement, and load balancing—no IP masquerading required.