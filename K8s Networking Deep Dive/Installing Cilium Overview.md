### 1. Cilium CLI: Your Primary Management Tool

The Cilium CLI is the go-to command-line utility for installing, managing, and troubleshooting Cilium:

- View the overall status of Cilium components
- Verify network connectivity across endpoints
- Run built-in network tests
- Enable Hubble for deep observability
- Install Cilium and addons

```bash
# Check the health of your Cilium cluster
$ cilium status

# Run a connectivity test between pods
$ cilium connectivity test

# Enable Hubble for network observability
$ cilium hubble enable

# Install Cilium into your Kubernetes cluster
$ cilium install
```

The Cilium CLI v0.14+ supports both direct CLI installs and Helm-style deployments, giving you full flexibility.

### 2. Installation Methods: CLI vs. Helm

Cilium can be installed in two interchangeable ways:

| Installation Method | Command Example | Benefits |
| ----------- | ----------- | ----------- |
| Cilium CLI | `cilium install` | All-in-one tool; built-in validation |
| Helm Chart | `helm install cilium cilium/cilium --version 1.x.y` | Familiar (хорошо знакомый) Helm workflow; chart config |

In this demo, we'll walk through both methods side by side.

### 3. Observability with Hubble

Hubble provides real-time visibility into network flows, service dependencies, and security policies. You can enable it:

- **During** Cilium installation:

  ```bash
  $ cilium install --enable-hubble
  ```

- **After** Cilium is up and running:

  ```bash
  $ cilium hubble enable
  ```

**Warning**

You must install Cilium before enabling Hubble, as Hubble relies on core Cilium components.

To interact with Hubble:

```bash
# Install Hubble CLI
$ curl -L --remote-name https://github.com/cilium/hubble-cli/releases/latest/download/hubble-linux-amd64.tar.gz
$ tar xzvf hubble-linux-amd64.tar.gz
$ sudo mv hubble /usr/local/bin/

# Check Hubble status
$ hubble status

# Stream live network events
$ hubble observe
```