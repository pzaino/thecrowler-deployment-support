# Helm User Content Contract

Chart version `0.2.0` adds an optional external ConfigMap contract for
deployment-specific CROWler content.

Configure:

```yaml
userContent:
  enabled: true
  agentsConfigMap: crowler-user-agents
  pluginsConfigMap: crowler-user-plugins
  rulesConfigMap: crowler-user-rules
  supportConfigMap: crowler-user-support
  rolloutToken: "content-version"
```

The ConfigMaps are mounted into Engine, API, and Events at:

```text
/app/user/agents
/app/user/plugins
/app/user/rules
/app/user/support
```

This does not mask the built-in:

```text
/app/agents
/app/plugins
/app/rules
/app/support
```

When externally managed ConfigMaps change, change `userContent.rolloutToken`
to roll Engine/API/Events.

The Terraform Helm deployment creates these ConfigMaps and rollout token
automatically.
