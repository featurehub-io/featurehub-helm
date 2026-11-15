# featurehub

![Version: 4.3.0](https://img.shields.io/badge/Version-4.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.10.1](https://img.shields.io/badge/AppVersion-1.10.1-informational?style=flat-square)

FeatueHub is an Enterprise Grade, Cloud Native Feature Management platform that is available to suite any organisations requirements. This fully supported Helm chart is the Open Source version of the product, which has all the same features as the [SaaS product](https://app.featurehub.io).

The project is hosted on [Github](https://github.com/featurehub-io/featurehub). It supports Postgres, MySQL, MariaDB or Oracle Database deployments, and uses NATS or Google PubSub as a streaming layer. Kinesis is available but has limited testing. Documentation on configuration is provided on [Featurehub Docs](https://docs.featurehub.io/featurehub/latest/configuration.html)

NATS and Postgres are *NOT* requirements of the project and are included only for convenience and evaluation. It is expected people will install their own requirements.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| FeatureHub | <info@featurehub.io> | <https://github.com/featurehub-io/featurehub-helm> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://nats-io.github.io/k8s/helm/charts/ | nats | 2.15.2 |
| https://repo.helmforge.dev | postgresql | 2.1.2 |

## Maintenance windows

FeatureHub 1.11 and later can keep the Admin app in maintenance mode, and keep SDKs working, while the Management
Repository (MR) is shut down, e.g. for a database upgrade. The
[Maintenance Windows](https://docs.featurehub.io/featurehub/latest/maintenance.html) docs explain the pieces. This chart
drives them all from `maintenance.mode`:

| `maintenance.mode` | Maintenance responder | Admin (non-`/features`) ingress traffic | MR replicas | Edge feature updates |
|---|---|---|---|---|
| `disabled` | not deployed | MR | normal | allowed |
| `warm` | deployed | MR | normal | allowed |
| `active` | deployed | maintenance responder | normal | blocked (503) |
| `shutdown` | deployed | maintenance responder | **0** | blocked (503) |
| `post` | deployed | maintenance responder | normal | blocked (503) |

`maintenance.start`, `maintenance.end` (ISO-8601 UTC timestamps ending in `Z`) and `maintenance.message` are required
in every mode except `disabled`. Setting them while `disabled` announces the window to Admin users ahead of time.

A typical window, one `helm upgrade` per step:

1. A few days ahead: set `start`, `end` and `message` (MR restarts, Admin users see the upcoming notice). If you use
   the Redis fallback (below), turn it on now.
2. `mode: warm` and wait for the maintenance responder to be ready.
3. `mode: active` when the window starts. Wait until every Edge logs `feature updates are now BLOCKED` (the kubelet can
   take a minute or two to update the file), then call the publish-all on **one** MR and wait for
   `redis: maintenance-publish-all: finished` in its log:
   ```sh
   kubectl port-forward <an mr pod> 8701:8701
   curl -X POST http://localhost:8701/maintenance/publish-all
   ```
4. `mode: shutdown`: MR is scaled to 0. Do the database work.
5. `mode: post`: MR starts again with the maintenance responder still taking the traffic, so you can check MR.
6. `mode: disabled`, and clear `start`, `end` and `message` (or leave them until the end time has passed).

The chart switches its own ingresses (`global.ingress` and `managementRepository.ingress`). If your ingress or load
balancer is managed outside the chart, point its Admin routes at the `<release>-maintenance-responder` Service (port
`8085`, the same as MR) during `active`, `shutdown` and `post`, and keep `/features` on Edge. Dacha2 keeps calling MR
directly throughout, which is what lets it notice MR has gone and fall back to Redis.

Changing the mode never restarts Edge or Dacha2. The Edge update block is a file in the fixed-name ConfigMap
`<release>-edge-update-block`, which Edge re-checks every `maintenance.edgeUpdateBlock.checkIntervalSeconds`.

### Redis fallback for Dacha2

With `redis.url` set, MR writes every environment and service account to Redis, and Dacha2 reads them on a cache miss
while MR is unavailable, so SDKs with API keys Dacha2 has not seen yet, and restarted Dacha2 pods, keep working. See
[Serving Dacha2 cache misses from Redis](https://docs.featurehub.io/featurehub/latest/maintenance.html#_redis_fallback),
including the Redis requirements (`maxmemory-policy noeviction`, authentication and TLS).

This chart does not deploy Redis. Use your cloud's managed Redis, or another chart. Redis is only needed around a
maintenance window, so you can create it before the window and remove it afterwards.

Turn it on in two steps:

1. Set `redis.url` (and `redis.password` or `redis.existingSecret`, and `redis.caCert` for a private CA) with
   `redis.dacha.enabled: false`. MR restarts (cheap, it holds no cache) and runs a full sync. Wait for
   `mr_redis_last_full_sync_seconds`.
2. Set `redis.dacha.enabled: true`. Dacha2 picks this up within `redis.dacha.configReloadSeconds`, **without
   restarting**.

Turn it off in the reverse order: `redis.dacha.enabled: false` first, then remove `redis.url`, then remove Redis.

Dacha2 re-reads its Redis settings from the `<release>-dacha-redis` ConfigMap and Secret, which are always mounted
(empty while Redis is off). That is why the Dacha2 pod template does not change when Redis is turned on or off. Do not
add anything to `dacha.podAnnotations` (or the global `podAnnotations`) that changes with the Redis settings, such as a
checksum of those values, or Dacha2 will restart and empty its cache anyway. The same applies to Edge and the update
block ConfigMap.

If you use `redis.existingSecret`, the Secret must contain two keys: the password under `redis.existingSecretPasswordKey`
(default `password`) for MR, and `redis.properties` for Dacha2:

```sh
kubectl create secret generic featurehub-redis \
  --from-literal=password='<password>' \
  --from-literal=redis.properties='dacha2.redis.password=<password>'
```

Create the Secret before setting `redis.existingSecret`. Setting or changing `redis.existingSecret` restarts Dacha2 once,
because the mounted Secret's name is part of its pod template.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dacha.affinity | object | `{}` |  |
| dacha.enabled | bool | `true` |  |
| dacha.envAsAppConfigFile | bool | `true` | If `true`, entries from `environmentVars` and `envFromSecret` fields will be mapped to configuration files. `environmentVars` to /etc/app-config/application.properties `envFromSecret` to /etc/app-config/secrets.properties Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| dacha.envAsApplicationProperties | bool | `true` | If `true`, entries from `environmentVars` will be mapped to /etc/app-config/application.properties file To mount secret settings as /etc/app-config/application.properties see volume fields Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| dacha.envFromSecret | string | `""` | Name of the secret containing secret properties, to be exposed as environment variables to dacha deployment. Create the secret in advance, then reference it here. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case Entries of the secret specified here are the same as would be specified in /etc/app-config/secrets.properties |
| dacha.environmentVars | object | `{"cache.pool-size":"10","management-repository.url":"http://featurehub-management-repository:8701"}` | Environment variables to be exposed to dacha deployment. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case. Entries accepted here are the same as would be specified in /etc/app-config/applications.properties. Note that `server.port` and `monitor.port` use their default values of `8085` and `8701` respectively, to make it easier to implement the deployment, service and the prometheus serviceMonitor manifests. |
| dacha.environmentVars."cache.pool-size" | string | `"10"` | thread pool size for processing cache updates |
| dacha.environmentVars."management-repository.url" | string | `"http://featurehub-management-repository:8701"` | Dacha2 calls MR via the Management API to avoid public internet traffic (by default) |
| dacha.extraContainers | list | `[]` | List of extra containers to add to Dacha Pod |
| dacha.extraEnvironmentVars | object | `{}` | Extra environment variables to be exposed to dacha deployment. In terms of environment variable setting, this is the same as `environmentVars` field. The only difference is that if `envAsAppConfigFile: true`, only entries from `environmentVars` will be mapped to the application.properties configuration file, and not the ones from `extraEnvironmentVars`. |
| dacha.extraVolumeMounts | list | `[]` | List of extra mounts to add to Dacha Deployment |
| dacha.extraVolumes | list | `[]` | List of extra volumes to add to Dacha Deployment |
| dacha.image.repository | string | `"featurehub/dacha2"` |  |
| dacha.image.tag | string | `""` |  |
| dacha.imagePullSecrets | list | `[]` |  |
| dacha.ingress.annotations | object | `{}` |  |
| dacha.ingress.className | string | `""` |  |
| dacha.ingress.enabled | bool | `false` |  |
| dacha.ingress.hosts | list | `[]` |  |
| dacha.ingress.tls | list | `[]` |  |
| dacha.livenessProbe | object | `{"failureThreshold":1,"httpGet":{"path":"/health/liveness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"timeoutSeconds":3}` | this allows you to override the values of the liveness probe for dacha |
| dacha.nodeSelector | object | `{}` |  |
| dacha.podAnnotations | object | `{}` |  |
| dacha.podDisruptionBudget.enabled | bool | `true` |  |
| dacha.podDisruptionBudget.maxUnavailable | int | `1` |  |
| dacha.podLabels | object | `{}` | this allows you to specify pod labels that will appear on dacha deployments |
| dacha.podSecurityContext.fsGroup | int | `999` |  |
| dacha.prometheus | object | `{"enabled":false,"labels":{}}` | Prometheus configuration |
| dacha.prometheus.enabled | bool | `false` | Whether to enable or disable prometheus metrics endpoints, and serviceMonitor If enabled, metrics are exposed on port 8701, on /metrics endpoint |
| dacha.prometheus.labels | object | `{}` | Labels for the Prometheus Operator to handle the serviceMonitor |
| dacha.pullPolicy | string | `"IfNotPresent"` |  |
| dacha.readinessProbe | object | `{"failureThreshold":1,"httpGet":{"path":"/health/readiness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"successThreshold":2,"timeoutSeconds":3}` | this allows you to override the values of the readiness probe for dacha |
| dacha.replicaCount | int | `2` |  |
| dacha.resources | object | `{}` |  |
| dacha.securityContext.runAsNonRoot | bool | `true` |  |
| dacha.securityContext.runAsUser | int | `999` |  |
| dacha.serviceAccount.annotations | object | `{}` |  |
| dacha.serviceAccount.create | bool | `true` |  |
| dacha.serviceAccount.labels | object | `{}` |  |
| dacha.serviceAccount.name | string | `""` |  |
| dacha.strategy | object | `{}` |  |
| dacha.tolerations | list | `[]` |  |
| edge.affinity | object | `{}` |  |
| edge.enabled | bool | `true` |  |
| edge.envAsAppConfigFile | bool | `true` | If `true`, entries from `environmentVars` and `envFromSecret` fields will be mapped to configuration files. `environmentVars` to /etc/app-config/application.properties `envFromSecret` to /etc/app-config/secrets.properties Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| edge.envAsApplicationProperties | bool | `true` | If `true`, entries from `environmentVars` will be mapped to /etc/app-config/application.properties file To mount secret settings as /etc/app-config/application.properties see volume fields Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| edge.envFromSecret | string | `""` | Name of the secret containing secret properties, to be exposed as environment variables to edge deployment. Create the secret in advance, then reference it here. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case Entries of the secret specified here are the same as would be specified in /etc/app-config/secrets.properties |
| edge.environmentVars | object | `{"dacha.timeout.read":"12000","dacha.url.default":"http://featurehub-dacha:8600","listen.pool-size":"30","maxSlots":"30","server.gracePeriodInSeconds":"10","update.pool-size":"30"}` | Environment variables to be exposed to edge deployment. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case. Entries accepted here are the same as would be specified in /etc/app-config/applications.properties. Note that `server.port` and `monitor.port` use their default values of `8085` and `8701` respectively, to make it easier to implement the deployment, service and the prometheus serviceMonitor manifests. |
| edge.environmentVars."dacha.timeout.read" | string | `"12000"` | this should reflect the sizing/capability of your database to respond to the 1st time a key is requested |
| edge.environmentVars."dacha.url.default" | string | `"http://featurehub-dacha:8600"` | the location of your dacha service, along with the port |
| edge.environmentVars."listen.pool-size" | string | `"30"` | thread pool for processing incoming requests. Does not reflect number of clients |
| edge.environmentVars."server.gracePeriodInSeconds" | string | `"10"` | how long to wait for connections to complete before shutting server down |
| edge.environmentVars."update.pool-size" | string | `"30"` | thread pool for updates |
| edge.environmentVars.maxSlots | string | `"30"` | how long SSE connections are allowed to connect for |
| edge.extraContainers | list | `[]` | List of extra containers to add to Edge Pod |
| edge.extraEnvironmentVars | object | `{}` | Extra environment variables to be exposed to edge deployment. In terms of environment variable setting, this is the same as `environmentVars` field. The only difference is that if `envAsAppConfigFile: true`, only entries from `environmentVars` will be mapped to the application.properties configuration file, and not the ones from `extraEnvironmentVars`. |
| edge.extraVolumeMounts | list | `[]` | List of extra mounts to add to Edge Deployment |
| edge.extraVolumes | list | `[]` | List of extra volumes to add to Edge Deployment |
| edge.image.repository | string | `"featurehub/edge"` |  |
| edge.image.tag | string | `""` |  |
| edge.imagePullSecrets | list | `[]` |  |
| edge.ingress.annotations | object | `{}` |  |
| edge.ingress.className | string | `""` |  |
| edge.ingress.enabled | bool | `false` |  |
| edge.ingress.hosts | list | `[]` |  |
| edge.ingress.tls | list | `[]` |  |
| edge.livenessProbe | object | `{"failureThreshold":2,"httpGet":{"path":"/health/liveness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"timeoutSeconds":3}` | this allows you to override the values of the liveness probe for edge |
| edge.nodeSelector | object | `{}` |  |
| edge.podAnnotations | object | `{}` |  |
| edge.podDisruptionBudget.enabled | bool | `true` |  |
| edge.podDisruptionBudget.maxUnavailable | int | `1` |  |
| edge.podLabels | object | `{}` | this allows you to specify pod labels that will appear on edge deployments |
| edge.podSecurityContext.fsGroup | int | `999` |  |
| edge.prometheus | object | `{"enabled":false,"labels":{}}` | Prometheus configuration |
| edge.prometheus.enabled | bool | `false` | Whether to enable or disable prometheus metrics endpoints, and serviceMonitor If enabled, metrics are exposed on port 8701, on /metrics endpoint |
| edge.prometheus.labels | object | `{}` | Labels for the Prometheus Operator to handle the serviceMonitor |
| edge.pullPolicy | string | `"IfNotPresent"` |  |
| edge.readinessProbe | object | `{"failureThreshold":2,"httpGet":{"path":"/health/readiness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"successThreshold":2,"timeoutSeconds":3}` | this allows you to override the readiness probe for edge |
| edge.replicaCount | int | `2` |  |
| edge.resources | object | `{}` |  |
| edge.securityContext.runAsNonRoot | bool | `true` |  |
| edge.securityContext.runAsUser | int | `999` |  |
| edge.serviceAccount.annotations | object | `{}` |  |
| edge.serviceAccount.create | bool | `true` |  |
| edge.serviceAccount.labels | object | `{}` |  |
| edge.serviceAccount.name | string | `""` |  |
| edge.strategy | object | `{}` |  |
| edge.tolerations | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| global.envAsApplicationProperties | bool | `true` | If `true`, entries from `environmentVars` will be mapped to /etc/app-config/common.properties file To mount secret settings as /etc/app-config/common.properties see volume fields Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| global.envFromSecret | string | `""` | Name of the secret containing secret properties, to be exposed as environment variables to Management Repository, Edge and Dacha deployments. Create the secret in advance, then reference it here. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case Entries of the secret specified here are the same as would be specified in /etc/app-config/secrets.properties |
| global.environmentVars | object | `{"nats.urls":"nats://featurehub-nats"}` | Environment variables to be exposed to Management Repository, Edge and Dacha deployments. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case. Entries accepted here are the same as would be specified in /etc/app-config/common.properties. |
| global.extraCommonConfigFiles[0].configMapSuffix | string | `"log4j2-xml"` |  |
| global.extraCommonConfigFiles[0].content | string | `"<Configuration packages=\"cd.connect.logging\" monitorInterval=\"30\" verbose=\"true\">\n   <Appenders>\n     <Console name=\"STDOUT\" target=\"SYSTEM_OUT\">\n       <ConnectJsonLayout/>\n     </Console>\n   </Appenders>\n\n   <Loggers>\n     <AsyncLogger name=\"io.featurehub\" level=\"debug\"/>\n     <!--\n     <AsyncLogger name=\"io.ebean.SQL\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.TXN\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.SUM\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.DDL\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.cache.QUERY\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.cache.BEAN\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.cache.COLL\" level=\"trace\"/>\n     <AsyncLogger name=\"io.ebean.cache.NATKEY\" level=\"trace\"/>\n\n     <AsyncLogger name=\"jersey-logging\" level=\"trace\"/>\n     <AsyncLogger name=\"io.featurehub.db\" level=\"trace\"/>\n     -->\n     <AsyncLogger name=\"io.featurehub.edge.features\" level=\"debug\"/>\n\n   <AsyncLogger name=\"net.stickycode\" level=\"warn\"/>\n   <AsyncLogger name=\"org.glassfish.jersey.server.wadl\" level=\"error\"/>\n   <AsyncLogger name=\"io.avaje.config\"  level=\"warn\"/>\n   <AsyncLogger name=\"org.hibernate\" level=\"error\"/>\n\n\n   <AsyncRoot level=\"info\">\n       <AppenderRef ref=\"STDOUT\"/>\n     </AsyncRoot>\n   </Loggers>\n</Configuration>"` |  |
| global.extraCommonConfigFiles[0].fileName | string | `"log4j2.xml"` |  |
| global.extraEnvironmentVars | object | `{}` | Extra environment variables to be exposed to Management Repository, Edge and Dacha deployments. In terms of environment variable setting, this is the same as `environmentVars` field. The only difference is that if `envAsAppConfigFile: true`, only entries from `environmentVars` will be mapped to the common.properties configuration file, and not the ones from `extraEnvironmentVars`. |
| global.extraVolumeMounts | list | `[]` | List of extra mounts to add to Management Repository Deployment |
| global.extraVolumes | list | `[]` | List of extra volumes to add to Management Repository Deployment |
| global.ingress.annotations | list | `[]` |  |
| global.ingress.enabled | bool | `true` |  |
| global.ingress.ingressClassName | string | `""` | specify the ingress class name if thats what makes yor ingress work. E.g. in AWS its "alb" |
| global.intranet | bool | `false` | if set to true, then MR will serve the intranet version of the application which does not require external HTML dependencies |
| global.podLabels | object | `{}` | this allows you to specify pod labels that will appear on all deployments |
| global.urlPath | string | `""` | the default url path is to mount as root, this lets you mount where ever you like, but it affects the health checks |
| googlepubsub.backOffInSeconds | int | `20` | how long to backoff when failing to process a request from an incoming subscription |
| googlepubsub.channels | object | `{"edgemr":{"description":"Updates from Edge are published through this channel and picked up by MR","subscription":"enricher-updates-sub","topicName":"featurehub-edge-updates"},"enrichedEvents":{"topicName":"enriched-feature-data"},"featureChangeMessage":{"description":"this is issued when a feature has changed, it is a complex diff message. It may or may not be enabled","topicName":"featurehub-messaging-channel"},"featureEnricher":{"description":"This channel is used for the initial enriched events. It is a queue.","subscription":"enricher-updates-sub","topicName":"enricher-updates-sub"},"featureWebhook":{"description":"dacha broadcasts to the topic, edge listens","subscription":"featurehub-enriched-events","topicName":"featurehub-enriched-events-webhooks"},"mrdacha":{"dachaPrefix":"featurehub-dacha2-listener","topicName":"featurehub-mr-dacha2"},"mredge":{"edgePrefix":"featurehub-edge-listener","topicName":"featurehub-mr-edge"},"stats":{"topicName":"featurehub-stats"}}` | feed these from something like Terraform, Pulumi or a Crossplane XRD. For more details see [PubSub config docs](https://docs.featurehub.io/featurehub/latest/configuration.html#_googles_pubsub) |
| googlepubsub.channels.featureEnricher.subscription | string | `"enricher-updates-sub"` | dacha is listening to this |
| googlepubsub.channels.featureEnricher.topicName | string | `"enricher-updates-sub"` | MR publishes this. |
| googlepubsub.emulator | object | `{"enabled":true,"host":"pubsub-emulator:8075"}` | is the pubsub implementation a copy of the Docker emulator |
| googlepubsub.enabled | bool | `false` | whether to enable chart for using Google PubSub |
| googlepubsub.project | string | `"featurehub"` |  |
| maintenance | object | `{"edgeUpdateBlock":{"checkIntervalSeconds":30,"enabled":true},"end":"","message":"","mode":"disabled","responder":{"affinity":{},"envFromSecret":"","environmentVars":{},"extraVolumeMounts":[],"extraVolumes":[],"image":{"repository":"featurehub/maintenance-responder","tag":""},"imagePullSecrets":[],"interceptPrefixes":"","livenessProbe":{"failureThreshold":2,"httpGet":{"path":"/health/liveness","port":"metrics"},"initialDelaySeconds":10,"periodSeconds":20,"timeoutSeconds":3},"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false,"maxUnavailable":1},"podLabels":{},"podSecurityContext":{"fsGroup":999},"prometheus":{"enabled":false,"labels":{}},"pullPolicy":"IfNotPresent","readinessProbe":{"failureThreshold":2,"httpGet":{"path":"/health/readiness","port":"metrics"},"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":3},"replicaCount":1,"resources":{},"securityContext":{"runAsNonRoot":true,"runAsUser":999},"serviceAccount":{"annotations":{},"create":true,"labels":{},"name":""},"strategy":{},"tolerations":[]},"start":""}` | ----------------------------------------------------------------------------- # |
| maintenance.edgeUpdateBlock.checkIntervalSeconds | int | `30` | How often Edge checks for the update block file |
| maintenance.edgeUpdateBlock.enabled | bool | `true` | Mount the update block file into Edge, so it refuses feature updates (SDK/test API PUTs) with a 503 while the maintenance responder takes the traffic. The file is changed without restarting Edge. Turning this on or off restarts Edge. |
| maintenance.end | string | `""` | The end of the window, in the same format. Also used for the Retry-After header. |
| maintenance.message | string | `""` | The message shown to Admin app users. |
| maintenance.mode | string | `"disabled"` | The stage of the maintenance window. Use them in this order: disabled -> warm -> active -> shutdown -> post -> disabled. `disabled`: normal operation, the maintenance responder is not deployed. `warm`: the maintenance responder is deployed but receives no traffic. `active`: all non-Edge ingress traffic goes to the maintenance responder and Edge blocks feature updates. MR is still running: call its maintenance publish-all now. `shutdown`: as active, and MR is scaled to 0 for the database work. `post`: MR is scaled back up, the maintenance responder still takes the traffic so you can check MR. |
| maintenance.responder | object | `{"affinity":{},"envFromSecret":"","environmentVars":{},"extraVolumeMounts":[],"extraVolumes":[],"image":{"repository":"featurehub/maintenance-responder","tag":""},"imagePullSecrets":[],"interceptPrefixes":"","livenessProbe":{"failureThreshold":2,"httpGet":{"path":"/health/liveness","port":"metrics"},"initialDelaySeconds":10,"periodSeconds":20,"timeoutSeconds":3},"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false,"maxUnavailable":1},"podLabels":{},"podSecurityContext":{"fsGroup":999},"prometheus":{"enabled":false,"labels":{}},"pullPolicy":"IfNotPresent","readinessProbe":{"failureThreshold":2,"httpGet":{"path":"/health/readiness","port":"metrics"},"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":3},"replicaCount":1,"resources":{},"securityContext":{"runAsNonRoot":true,"runAsUser":999},"serviceAccount":{"annotations":{},"create":true,"labels":{},"name":""},"strategy":{},"tolerations":[]}` | The maintenance responder stands in for MR: it serves the Admin app and answers the API with a 503 and Retry-After. It is deployed in every mode except `disabled`, and never connects to the database or the messaging layer. |
| maintenance.responder.envFromSecret | string | `""` | Name of an existing secret whose keys are exposed as environment variables |
| maintenance.responder.environmentVars | object | `{}` | Extra environment variables for the maintenance responder, e.g. CORS settings |
| maintenance.responder.interceptPrefixes | string | `""` | Comma-separated path prefixes that get a 503. Empty uses the image default (mr-api,saml,oauth,dacha2,info). |
| maintenance.start | string | `""` | The start of the window, an ISO-8601 UTC timestamp ending in Z, e.g. 2026-11-17T10:15:30Z. Setting start, end and message while the mode is `disabled` announces the window to Admin app users ahead of time (and restarts MR). All three are required in any other mode. |
| managementRepository.affinity | object | `{}` |  |
| managementRepository.enabled | bool | `true` | do you want to run the Management Repository? |
| managementRepository.envAsApplicationProperties | bool | `true` | If `true`, entries from `environmentVars` will be mapped to /etc/app-config/application.properties file To mount secret settings as /etc/app-config/application.properties see volume fields Used for retrocompatiblity with FeatureHub controller versions lower than 1.5.0 https://docs.featurehub.io/featurehub/latest/installation.html#_run_configuration |
| managementRepository.envFromSecret | string | `""` | Name of the secret containing secret properties, to be exposed as environment variables to edge deployment. Create the secret in advance, then reference it here. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case Entries of the secret specified here are the same as would be specified in /etc/app-config/secrets.properties |
| managementRepository.environmentVars | object | `{"db.connections":"20","db.password":"featurehub","db.url":"jdbc:postgresql://featurehub-postgresql:5432/featurehub","db.username":"featurehub","portfolio.admin.group.suffix":"Administrators"}` | Environment variables to be exposed to management-repository deployment. As of 1.5.0 all FeatureHub controller properties are available as environment variables using the same case. Entries accepted here are the same as would be specified in /etc/app-config/applications.properties. Note that `server.port` and `monitor.port` use their default values of `8085` and `8701` respectively, to make it easier to implement the deployment, service and the prometheus serviceMonitor manifests. |
| managementRepository.environmentVars."db.connections" | string | `"20"` | the maximum number of database connections that will be allowed |
| managementRepository.environmentVars."db.password" | string | `"featurehub"` | normally you would not want this, but its for the example postgres |
| managementRepository.environmentVars."db.url" | string | `"jdbc:postgresql://featurehub-postgresql:5432/featurehub"` | the connection string. Google CloudSQL libraries are included for Postgres and MySQL |
| managementRepository.environmentVars."db.username" | string | `"featurehub"` | the Database's Username |
| managementRepository.environmentVars."portfolio.admin.group.suffix" | string | `"Administrators"` | when a Portfolio Admin group is created, this is added to the name of the portfolio. Change for a different language |
| managementRepository.extraContainers | list | `[]` | List of extra containers to add to Management Repository Pod |
| managementRepository.extraEnvironmentVars | object | `{}` | Extra environment variables to be exposed to management-repository deployment. In terms of environment variable setting, this is the same as `environmentVars` field. The only difference is that if `envAsAppConfigFile: true`, only entries from `environmentVars` will be mapped to the application.properties configuration file, and not the ones from `extraEnvironmentVars`. |
| managementRepository.extraVolumeMounts | list | `[]` | List of extra mounts to add to Management Repository Deployment |
| managementRepository.extraVolumes | list | `[]` | List of extra volumes to add to Management Repository Deployment |
| managementRepository.image.repository | string | `"featurehub/mr"` |  |
| managementRepository.image.tag | string | `""` |  |
| managementRepository.imagePullSecrets | list | `[]` |  |
| managementRepository.ingress.annotations | object | `{}` |  |
| managementRepository.ingress.className | string | `""` |  |
| managementRepository.ingress.enabled | bool | `false` |  |
| managementRepository.ingress.hosts | list | `[]` |  |
| managementRepository.ingress.tls | list | `[]` |  |
| managementRepository.initContainers | object | `{}` |  |
| managementRepository.livenessProbe | object | `{"failureThreshold":2,"httpGet":{"path":"/health/liveness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"timeoutSeconds":3}` | this allows you to override the values of the liveness probe for MR |
| managementRepository.nodeSelector | object | `{}` |  |
| managementRepository.podAnnotations | object | `{}` |  |
| managementRepository.podDisruptionBudget.enabled | bool | `true` |  |
| managementRepository.podDisruptionBudget.maxUnavailable | int | `1` |  |
| managementRepository.podLabels | object | `{}` | this allows you to specify pod labels that will appear on MR deployments |
| managementRepository.podSecurityContext.fsGroup | int | `999` |  |
| managementRepository.prometheus | object | `{"enabled":false,"labels":{}}` | Prometheus configuration |
| managementRepository.prometheus.enabled | bool | `false` | Whether to enable or disable prometheus metrics endpoints, and serviceMonitor If enabled, metrics are exposed on port 8701, on /metrics endpoint |
| managementRepository.prometheus.labels | object | `{}` | Labels for the Prometheus Operator to handle the serviceMonitor |
| managementRepository.pullPolicy | string | `"IfNotPresent"` |  |
| managementRepository.readinessProbe | object | `{"failureThreshold":2,"httpGet":{"path":"/health/readiness","port":"metrics"},"initialDelaySeconds":20,"periodSeconds":20,"successThreshold":2,"timeoutSeconds":3}` | this allows you to override the readiness probe |
| managementRepository.replicaCount | int | `1` | how many copies |
| managementRepository.resources | object | `{}` |  |
| managementRepository.securityContext.runAsNonRoot | bool | `true` |  |
| managementRepository.securityContext.runAsUser | int | `999` |  |
| managementRepository.serviceAccount.annotations | object | `{}` |  |
| managementRepository.serviceAccount.create | bool | `true` |  |
| managementRepository.serviceAccount.labels | object | `{}` |  |
| managementRepository.serviceAccount.name | string | `""` |  |
| managementRepository.strategy | object | `{}` |  |
| managementRepository.tolerations | list | `[]` |  |
| nameOverride | string | `""` |  |
| nats | object | `{"config":{"cluster":{"enabled":true,"name":"featurehub","replicas":3}},"enabled":true}` | ----------------------------------------------------------------------------- # |
| podAnnotations | object | `{}` |  |
| postgresql | object | `{"auth":{"database":"featurehub","password":"featurehub","postgresPassword":"postgresql","username":"featurehub"},"enabled":true,"standalone":{"persistence":{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"128Mi","storageClass":"standard"}}}` | ----------------------------------------------------------------------------- # |
| redis | object | `{"caCert":"","dacha":{"configReloadSeconds":30,"enabled":true},"existingSecret":"","existingSecretPasswordKey":"password","keyPrefix":"","managementRepository":{"enabled":true},"mode":"standalone","password":"","sentinelMaster":"","url":"","username":""}` | ----------------------------------------------------------------------------- # |
| redis.caCert | string | `""` | The PEM CA certificate(s) to trust for rediss://, if the server is not signed by a public CA |
| redis.dacha.configReloadSeconds | int | `30` | How often Dacha2 re-reads its Redis settings |
| redis.dacha.enabled | bool | `true` | Turn the Redis fallback on for Dacha2 when url is set. Dacha2 picks this up without restarting. Enable MR first, wait for its full sync (`mr_redis_last_full_sync_seconds`), then enable Dacha2. |
| redis.existingSecret | string | `""` | The name of a Secret you created, instead of `password`. It needs the key `existingSecretPasswordKey` (for MR) AND a `redis.properties` key for Dacha2 containing `dacha2.redis.password=<the password>`, because Dacha2 re-reads its Redis settings from files at runtime. The Secret is always mounted into Dacha2, so create it before setting this (setting or changing this restarts Dacha2 once). |
| redis.keyPrefix | string | `""` | Empty uses the default prefix (`featurehub`). Use a different prefix for each FeatureHub install sharing one Redis. |
| redis.managementRepository.enabled | bool | `true` | Turn Redis on for MR when url is set. Changing any redis setting restarts MR, which is cheap as MR holds no cache. |
| redis.mode | string | `"standalone"` | standalone, sentinel or cluster. For sentinel and cluster, list several host:port pairs separated by commas in the url. |
| redis.password | string | `""` | The Redis password. The chart puts it in a Secret. Use this or `existingSecret`. |
| redis.sentinelMaster | string | `""` | The master name, required for sentinel mode |
| redis.url | string | `""` | Enables the Redis fallback, e.g. `redis://redis:6379` or `rediss://10.0.0.3:6378` (TLS). Do not put the password in the url, use `password` or `existingSecret`. |
