CNIs are third-party Network Plugins that provide critical networking functionalities for Kubernetes clusters. These include creating and managing network interfaces for containers, allocating IP addresses to pods, and enabling communication between pods across different nodes in the cluster.

Common examples of Network Plugins include *Weave Net*, *Calico*, *Flannel*, *Cilium*, and *Canal*. Each of these network plugins possesses (обладают) unique features and benefits, with one critical aspect being the enforcement (исполнение) of Network Policies.

When a network policy is defined within a Kubernetes environment, the network plugin assumes (берет на себя) the responsibility of creating corresponding rules in the underlying network infrastructure. This ensures (это гарантирует) the policies are enforced (применяются) as expected, thus (таким образом) playing a key role in maintaining the integrity (поддержании целостности) of network traffic within the Kubernetes cluster.

Network plugins such as *Calico* or *Weave Net* natively (изначально) provide all the necessary functionality to enforce these policies.

In contrast, *Flannel* does not support Network Policies. This is primarily due to its design goal of simplicity. *Flannel* was designed to solve Kubernetes networking problems - it creates a mesh network of interconnected hosts and routes the pod-to-pod traffic through this mesh. However, this simplicity means it lacks (ему не хватает) the advanced features required to understand and enforce network policies. It is essential to understand these differences and limitations when deciding on the appropriate CNI for your Kubernetes cluster.

Установить *Flannel* в один кластер: `kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --context cluster1`. Ставится в namespace `kube-flannel`.

Установить *Weave Net* в другой кластер: `kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml --context cluster2`. Ставится в namespace `kube-system`.

