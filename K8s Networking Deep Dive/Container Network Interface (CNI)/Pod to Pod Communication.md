Cilium's CNI plugin provides transparent pod-to-pod connectivity, including support for DNS A-records for pod hostnames. This guide walks through verifying Cilium, deploying pods, inspecting veth interfaces, and testing direct IP and DNS-based communication in a Kubernetes cluster.

### 1. Verify Cilium Status

First, confirm that Cilium and its components are up and running:

```bash
$ cilium status
```

You should see output similar to:

```
Cilium:            OK
Operator:          OK
Envoy DaemonSet:   disabled (using embedded mode)
Hubble Relay:      disabled
ClusterMesh:       disabled


Deployment          cilium-operator      Desired: 1/1, Ready: 1/1, Available: 1/1
DaemonSet           cilium               Desired: 2/2, Ready: 2/2, Available: 2/2
Containers:         cilium (Running)
                    cilium-operator (Running)
Cluster Pods:       2/2 managed by Cilium
Helm chart version: cilium
Image versions:     cilium: quay.io/cilium/cilium:v1.15.3
                    cilium-operator: quay.io/cilium/operator-generic:v1.15.3
```

If `Envoy DaemonSet` is disabled, Cilium is using its embedded proxy mode. For full L7 gateway features, enable the Envoy DaemonSet.

### 2. Deploy Pods and Observe Interface Creation

Apply a manifest (`pods.yaml`) to spin up three simple pods in the default namespace:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: pod2
spec:
  containers:
  - name: nginx
    image: nginx
```

```bash
$ kubectl apply -f pods.yaml
```

On your control‐plane node, tail the Cilium daemon logs to watch endpoint creation:

```bash
$ journalctl -u cilium -f
```

Or:

```bash
# Ищем pod cilium на ноде
$ kubectl describe node controlplane
$ kubectl -n kube-system logs -f <cilium-pod-name>
```

You should observe entries like:

```
time="2026-01-20T05:30:46Z" level=info msg="Create endpoint request" addressing="&{10.0.0.75 dd14237f-485f-4d19-aa14-f1a5e021ad44 default   }" containerID=97df177dfd226683085b378b8ab566298aa357c6dcdd0d705d2e925f066174dd containerInterface=eth0 datapathConfiguration="&{false false false false false <nil>}" interface=lxc67659437b8b7 k8sPodName=default/pod1 labels="[]" subsys=daemon sync-build=true
```

### 3. Inspect the Pod Interface and Network Namespace

On the node hosting `pod1`, list the CNI veth pair created by Cilium:

```bash
$ ip addr | grep -A1 lxc67659437b8b7
```

Example output:

```
26: lxc67659437b8b7@if25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 900 qdisc noqueue state UP group default qlen 1000
    link/ether a2:b6:db:d8:ef:bc brd ff:ff:ff:ff:ff:ff link-netns cni-33207a6f-bc61-ee1e-f3e6-66a89ddfbffc
```

Enter the network namespace and inspect `eth0`:

```bash
$ ip netns exec cni-33207a6f-bc61-ee1e-f3e6-66a89ddfbffc ip addr show eth0
# или
$ ip -n cni-33207a6f-bc61-ee1e-f3e6-66a89ddfbffc addr show eth0
```

Result:

```
25: eth0@if26: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 900 qdisc noqueue state UP group default qlen 1000
    link/ether 86:90:64:db:11:bf brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.0.0.75/32 scope global eth0
       valid_lft forever preferred_lft forever
```

This IP matches the address reported in the Cilium logs.

### 4. Delete and Recreate a Pod

Delete `pod1` and observe endpoint cleanup:

```bash
$ kubectl delete pod pod1
```

Cilium logs will include:

```
time="2026-01-20T05:39:22Z" level=info msg="Delete endpoint by containerID request" containerID=97df177dfd226683085b378b8ab566298aa357c6dcdd0d705d2e925f066174dd endpointID=1905 k8sNamespace=default k8sPodName=pod1 subsys=daemon
time="2026-01-20T05:39:22Z" level=info msg="Releasing key" key="[k8s:io.cilium.k8s.namespace.labels.kubernetes.io/metadata.name=default k8s:io.cilium.k8s.policy.cluster=kubernetes k8s:io.cilium.k8s.policy.serviceaccount=default k8s:io.kubernetes.pod.namespace=default]" subsys=allocator
time="2026-01-20T05:39:22Z" level=info msg="Removed endpoint" ciliumEndpointName=default/pod1 containerID=97df177dfd containerInterface= datapathPolicyRevision=1 desiredPolicyRevision=1 endpointID=1905 identity=43165 ipv4=10.0.0.75 ipv6= k8sPodName=default/pod1 subsys=endpoint
```

Verify the veth interface is removed:

```bash
$ ip addr | grep lxc67659437b8b7
$ ip -br addr show
```

Здесь параметр `br` = brief.

Recreate `pod1`:

```bash
$ kubectl apply -f pods.yaml
$ kubectl get pods -w
```

Watch for regeneration:

```
level=info msg="Rewrote endpoint BPF program" ciliumEndpointName=default/pod1 endpoint
```

### 5. Test Pod-to-Pod Connectivity by IP

Retrieve the pod IPs:

```bash
$ kubectl get pods -o=jsonpath='{range .items[*]}{.metadata.name}: {.status.podIP}{"\n"}{end}'
```

| Pod | IP |
| ----------- | ----------- |
| pod1 | 10.0.1.249 |
| pod2 | 10.0.1.14 |
| pod3 | 10.0.0.245 |

From `pod1`, ping `pod2` (same node):

```bash
$ kubectl exec -it pod1 -- ping -c 4 10.0.1.14
```

Ping `pod3` (remote node):

```bash
$ kubectl exec -it pod1 -- ping -c 4 10.0.0.245
```

And curl an HTTP server on `pod3` (port 80):

```bash
$ kubectl exec -it pod1 -- curl -vvv 10.0.0.245:80
```

### 6. Pod-to-Pod Communication via DNS A Records

Check the pod's DNS settings:

```bash
$ kubectl exec -it pod1 -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

Cilium automatically creates DNS A-records in the format:

```
<ip-with-dashes>.<namespace>.pod.cluster.local
```

For example, to ping `pod3` by DNS:

```bash
$ kubectl exec -it pod1 -- ping -c 4 10-0-0-245.default.pod.cluster.local
```

Or curl by name:

```bash
kubectl exec -it pod1 -- curl -vvv http://10-0-0-245.default.pod.cluster.local:80
```

**Warning**

Pod IPs are ephemeral. DNS A-records tied to pod IPs can break when the pod restarts. For stable discovery, use a Kubernetes Service.

### 7. Summary of Commands

| Task | Command |
| ----------- | ----------- |
| Verify Cilium status | `cilium status` |
| Deploy pods | `kubectl apply -f pods.yaml` |
| Tail Cilium logs | `journalctl -u cilium -f` |
| Show veth interfaces | `ip addr \| grep -A1 lxc` |
| Enter pod namespace | `ip netns exec <netns> ip addr show eth0` |
| Delete a pod | `kubectl delete pod pod1` |
| Test connectivity by IP | `kubectl exec -it pod1 -- ping -c 4 <pod IP>` |
| Test connectivity via DNS record | `kubectl exec -it pod1 -- ping -c 4 <dns record>` |