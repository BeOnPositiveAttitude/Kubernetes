In this lesson we cover Horizontal Pod Autoscaler (HPA) scaling policies - what they are, how they work, and how to configure them for predictable, stable autoscaling. HPA scaling policies define rules that tell Kubernetes how to change the number of pods in a Deployment/ReplicaSet based on metrics (CPU, memory, or custom/external metrics). Think of policies as the guardrails (ограждения, ограничители) that control how aggressively (агрессивно) or conservatively (консервативно) the HPA changes replica counts so your application has enough capacity without being overprovisioned.

Below are core concepts, examples, and practical guidance (руководство) to make HPA scaling behavior clear and actionable.

### Policy structure and attributes

Policies are specified under `behavior` in the HPA spec. Each policy entry contains:

- `type` - the unit of change. Supported values include:
  - `Pods` - an absolute number of pods to add or remove.
  - `Percent` - a percentage change relative to the current replica count.
- `value` - numeric amount associated with `type` (e.g., `4` pods or `10` percent).
- `periodSeconds` - the minimum time window (in seconds) that must elapse (пройти) between applications (применениями) of this policy (limits (ограничивает) how often that specific policy can be used).

#### Table: Policy attributes

| Attribute | Meaning | Example |
| --------: | ------- | ------- |
| `type` | Unit of change: `Pods` or `Percent` | `Pods` |
| `value` | Numeric amount for the chosen type | `4` or `10` |
| `periodSeconds` | Minimum seconds between policy applications | `60` |

When multiple policies are defined, you also control how the HPA chooses among them (как HPA выбирает среди них) using `selectPolicy` (set under `scaleUp` or `scaleDown`). `selectPolicy` typically accepts values such as `Max` or `Min` to choose the largest or smallest allowed change among applicable policies (позволяя выбрать наибольшее или наименьшее допустимое изменение из всех применимых политик).

#### Example combining `Pods` and `Percent` policies:

```yaml-
policies:
  - type: Pods
    value: 4
    periodSeconds: 60
  - type: Percent
    value: 10
    periodSeconds: 60
```

#### Explanation:

- The controller evaluates metrics frequently (by default every ~15s). A policy with `periodSeconds: 60` will not allow its change to be applied more often than once per 60 seconds.
- In the example above, the `Pods` policy allows changing replica count by up to 4 pods no more than once every 60 seconds (максимум на 4 пода, но не чаще одного раза в 60 секунд). The `Percent` policy allows a 10% change every 60 seconds.
- Use `selectPolicy` to control which policy is selected when more than one policy could apply.

#### Practical calculation example:

- Current replicas: `20`
- `Percent` policy: `10%` => allows `2` pods
- `Pods` policy: `4` => allows `4` pods
- With `selectPolicy: Max` the HPA would allow up to `4` pods; with `selectPolicy: Min` it would allow `2` pods.

Default HPA controller sync period is typically 15 seconds (`--horizontal-pod-autoscaler-sync-period`). Policies control the minimum interval for specific changes via (для внесения определенных изменений с помощью параметра) `periodSeconds`, so frequent metric checks (частые проверки метрик) can still be gated (могут быть ограничены) by policy limits.

Be cautious with overly aggressive policies (large `value` and short `periodSeconds`). They can cause rapid scaling that overshoots (превышающему) capacity or generates instability. Start conservative and validate with load testing.

### Configuring `behavior` with `scaleUp` and `scaleDown`

You configure policies inside `behavior.scaleUp` and `behavior.scaleDown`. You can also set `stabilizationWindowSeconds` to reduce thrashing (дребезг, интенсивное беспорядочное движение) for downward scaling (масштабирование в меньшую сторону).

Example full `behavior` section with `selectPolicy` and stabilization:

```yaml
behavior:
  scaleUp:
    policies:
      - type: Percent
        value: 20
        periodSeconds: 60
      - type: Pods
        value: 10
        periodSeconds: 60
    selectPolicy: Max
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 4
        periodSeconds: 60
    selectPolicy: Max
```

Notes on this example:

- `scaleUp` permits (допускает) up to 20% increase or 10 pods per 60 seconds, and `selectPolicy: Max` chooses the more permissive (более разрешительный) option when both apply.
- `scaleDown.stabilizationWindowSeconds: 300` instructs the controller to avoid scaling down below the highest recommended replica count seen in the last 5 minutes (максимального рекомендованного значения количества реплик, зафиксированного за последние 5 минут), helping prevent rapid downscales (резкое сокращение количества реплик) due to transient (временных) dips (спадов).

### Stabilization window (preventing thrash)

The stabilization window reduces thrashing - rapid up/down scaling - by making downward adjustments (корректировки в сторону уменьшения) conservative (осторожными, консервативными). Key points:

- `stabilizationWindowSeconds` is typically applied under `behavior.scaleDown` (you can also set it for `scaleUp` if needed).
- When set (e.g., `300` seconds), the HPA looks back over the last X seconds of recommendations and will not scale down below the highest recommendation seen during that window.
- Typical pattern: allow scale-ups to happen quickly, but make scale-downs cautious to avoid oscillation (колебания) due to short-lived (кратковременными, мимолетными) metric drops (падениями, просадками).

#### Example timeline (хронологии):

- Minute 1: HPA recommends 40 replicas (spike).
- Minute 2: metrics return and HPA recommends 30 replicas.
- With a 5-minute stabilization window, the controller will avoid reducing below the highest recommendation seen in that window (40) until the window elapses (до тех пор, пока окно не пройдет/завершится) or until later (последующие) metrics justify (обоснуют, объяснят) a smaller value.

### Defaults and best practices:

- Many clusters tune scale-up to react quickly (short or zero stabilization) and scale-down to use a longer window (e.g., 300 seconds).
- Adjust stabilization windows based on workload volatility (волатильность, изменчивость):
  - Latency-sensitive (чувствительные к задержке) workloads with short-lived spikes (кратковременными пиками): shorter windows.
  - Bursty (взрывные, всплесковые) or noisy (шумные) workloads: longer windows to reduce churn (оттока?).

### Practical guidance and tuning checklist

- Start conservative: combine small `Percent` values and modest (скромные) `Pods` caps (ограничения) to avoid overshoot (превышение, промахиваться).
- Use `selectPolicy` to control behavior when multiple policies could apply (`Max` vs `Min`).
- Set `periodSeconds` to limit how often a policy can be enforced; avoid extremely short intervals.
- Add `stabilizationWindowSeconds` for scale-down to prevent thrash.
- Validate behavior with controlled load tests while monitoring pods, application latency, and metrics.
- Monitor the HPA events (`kubectl describe hpa <name>`) to see recommendations, policy applications, and stabilization influences (влияние механизмов стабилизации).

### Summary

- Policies under `behavior` govern (управляют, определяют) how many pods (absolute or percent) can be added/removed and how often (`periodSeconds`).
- The HPA controller evaluates metrics frequently (default ~15s), but policy `periodSeconds` determines the minimum interval a specific rule can be applied.
- Use `selectPolicy` to choose how multiple policies are resolved (e.g., `Max` or `Min`).
- A stabilization window (especially for `scaleDown`) prevents rapid downscales and reduces oscillation.
- Combine policies, stabilization windows, and `selectPolicy` to balance responsiveness and stability for your application.

### Links and references

- [kube-controller-manager options](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)