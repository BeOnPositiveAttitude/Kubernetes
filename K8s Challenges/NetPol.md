One of the nginx based pod called `cyan-pod-cka28-trb` is running under `cyan-ns-cka28-trb` namespace and it is exposed within the cluster using `cyan-svc-cka28-trb` service.

This is a restricted pod so a network policy called `cyan-np-cka28-trb` has been created in the same namespace to apply some restrictions on this pod.


Two other pods called `cyan-white-cka28-trb` and `cyan-black-cka28-trb` are also running in the `default` namespace.


The nginx based app running on the `cyan-pod-cka28-trb` pod is exposed internally on the default nginx port (80).


**Expectation**: This app should only be accessible from the `cyan-white-cka28-trb` pod.


**Problem**: This app is not accessible from anywhere.


Troubleshoot this issue and fix the connectivity as per the requirement listed above.


Note: You can exec into `cyan-white-cka28-trb` and `cyan-black-cka28-trb` pods and test connectivity using the curl utility.


You may update the network policy, but make sure it is not deleted from the `cyan-ns-cka28-trb` namespace.

```yaml
apiVersion: v1
items:
- apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    creationTimestamp: "2024-04-16T06:19:26Z"
    generation: 1
    name: cyan-np-cka28-trb
    namespace: cyan-ns-cka28-trb
    resourceVersion: "5236"
    uid: a75c6be2-7dce-44e5-903b-d76d2e76a116
  spec:
    egress:
    - ports:
      - port: 8080
        protocol: TCP
    ingress:
    - from:
      - podSelector:
          matchLabels:
            app: cyan-white-cka28-trb
      ports:
      - port: 80
        protocol: TCP
    podSelector:
      matchLabels:
        app: cyan-app-cka28-trb
    policyTypes:
    - Ingress
    - Egress
  status: {}
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```