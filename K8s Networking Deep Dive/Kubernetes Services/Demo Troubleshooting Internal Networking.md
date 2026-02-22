In this step-by-step guide, you'll learn how to diagnose and resolve internal networking issues in Kubernetes using Cilium CNI, NetworkPolicies, and core troubleshooting techniques for Pods and Services. These best practices help ensure cluster connectivity and reliable application delivery.

### 1. Verify CNI Pod Health

Start by confirming that all Cilium components are running in the `kube-system` namespace:

```bash
$ kubectl -n kube-system get pods
# NAME                                   READY   STATUS    RESTARTS   AGE
# cilium-6xfl8                           1/1     Running   0          3m11s
# cilium-9qzr8                           1/1     Running   0          3m11s
# cilium-operator-58684c48c9-4rntb       1/1     Running   0          3m11s
# coredns-76f75df574-964d                1/1     Running   0          2m54s
```

Cilium consists of:

- A **DaemonSet** (`cilium-<pod>`) on each node
- A single **operator** pod managing cluster-wide CRDs

Inspect operator logs to catch any errors or warnings:

```bash
$ kubectl -n kube-system logs cilium-operator-58684c48c9-4rntb
```

For agent diagnostics, view a Cilium DaemonSet pod log:

```bash
$ kubectl -n kube-system logs cilium-6xfl8
```

#### 1.1 Using the Cilium CLI

If you have the Cilium CLI installed, quickly check cluster health:

```bash
$ cilium status
```

Example:

```
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 2, Ready: 2/2, Available: 2/2
Deployment             cilium-operator          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 2
                       cilium-operator          Running: 1
                       clustermesh-apiserver    
                       hubble-relay             
```

#### 1.2 Running `cilium-dbg`

Run the built-in debug tool to gather component status:

```bash
$ kubectl -n kube-system exec cilium-6xfl8 -- cilium-dbg status
```

Key checks include KVStore, API server connectivity, IPAM, and overall cluster health:

```
Kubernetes:              Ok   1.34 (v1.34.0) [linux/amd64]
Cilium:                  Ok   1.15.3 (v1.15.3-22dfbc58) 
Cluster health:          2/2 reachable   (2026-02-05T05:34:58Z)
```

#### 1.3 Checking Node Connectivity

Validate inter-node connectivity with `cilium-health`:

```bash
$ kubectl exec -n kube-system cilium-6xfl8 -- cilium-health status
```

```
Probe time:   2026-02-05T05:37:58Z
Nodes:
  kubernetes/controlplane (localhost):
    Host connectivity to 192.168.121.196:
      ICMP to stack:   OK, RTT=425.366µs
      HTTP to agent:   OK, RTT=229.229µs
    Endpoint connectivity to 10.0.0.24:
      ICMP to stack:   OK, RTT=424.06µs
      HTTP to agent:   OK, RTT=210.118µs
  kubernetes/node01:
    Host connectivity to 192.168.121.62:
      ICMP to stack:   OK, RTT=506.011µs
      HTTP to agent:   OK, RTT=466.985µs
    Endpoint connectivity to 10.0.1.129:
      ICMP to stack:   OK, RTT=426.385µs
      HTTP to agent:   OK, RTT=1.024029ms
```

### 2. Inspect Network Policies

NetworkPolicies can block unintended (непредусмотренные) traffic flows. List all policies across namespaces:

```bash
$ kubectl get networkpolicies.networking.k8s.io -A
# NAMESPACE   NAME                  POD-SELECTOR    AGE
# default     default-deny-egress   <none>          21m
```

Describe a restrictive policy:

```bash
kubectl -n default describe networkpolicies.networking.k8s.io default-deny-egress
```

```
PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
Not affecting ingress traffic
Allowing egress traffic:
   <none> (Selected pods are isolated for egress connectivity)
Policy Types: Egress
```

**Warning**

Deleting or modifying NetworkPolicies in production can expose workloads. Always validate in a non-production namespace first.

#### 2.1 Testing Egress Connectivity

Launch a temporary pod to test outbound access:

```bash
$ kubectl run --rm -i --tty debug-pod \
    --image=curlimages/curl \
    --restart=Never \
    -- curl www.google.com --connect-timeout 2
```

- If the request hangs, the policy is blocking egress.
- To restore connectivity, delete the policy:

  ```bash
  $ kubectl -n default delete networkpolicy default-deny-egress
  ```

Re-run the curl test to confirm successful egress.

### 3. Troubleshoot Pods and Services

#### 3.1 Checking Pod Status and Logs

List application pods:

```bash
$ kubectl get pods
```

If a pod is running but not behaving (работает некорректно), inspect its details and events:

```bash
$ kubectl describe pod nginx-deployment-56fcf95486-7d2dw
```

Follow up by streaming the logs:

```bash
$ kubectl logs -f nginx-deployment-56fcf95486-7d2dw
```

#### 3.2 Port-Forwarding to the Pod

Test direct connectivity by forwarding local port 8080 to the pod's port 80:

```bash
$ kubectl port-forward deployment/nginx-deployment 8080:80
```

Open your browser or use `curl http://localhost:8080` to verify the service response.

#### 3.3 Verifying Service Endpoints

Services provide stable access to Pods. If port-forward works on the pod but fails on the Service:

1. Describe the Service:

   ```bash
   $ kubectl describe svc nginx-service
   ```

2. If you see `Endpoints: <none>`, the selector may not match any Pods.

3. Check the Pod labels:

   ```bash
   $ kubectl get pod nginx-deployment-56fcf95486-7d2dw -o=jsonpath='{.metadata.labels}'
   ```

4. Edit the Service selector to match the Pod labels:

   ```bash
   $ kubectl edit svc nginx-service
   # Update selector from app=nginx-website to app=nginx
   ```

5. Confirm the endpoint appears:

   ```bash
   $ kubectl describe svc nginx-service
   # Endpoints: 10.0.0.247:80
   ```

6. Forward traffic via the Service:

   ```bash
   kubectl port-forward svc/nginx-service 8080:80
   ```

### 4. Summary

In this tutorial, you learned how to:

- Validate Cilium CNI health with pod status, logs, and CLI tools (`cilium status`, `cilium-debug`, `cilium-health`).
- Inspect and test the impact of **NetworkPolicies** on egress traffic.
- Diagnose Pod and Service connectivity with `kubectl describe`, `logs`, `port-forwarding`, and selector verification.

Following these steps will help you quickly identify and resolve internal networking issues in your Kubernetes cluster.