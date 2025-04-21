# featurehub

![Version: 4.1.5](https://img.shields.io/badge/Version-4.1.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.9.0](https://img.shields.io/badge/AppVersion-1.9.0-informational?style=flat-square)

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
| https://nats-io.github.io/k8s/helm/charts/ | nats | 1.1.5 |
| https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami | postgresql | 12.1.13 |

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
| nats | object | `{"cluster":{"enabled":true,"name":"featurehub","replicas":3},"enabled":true,"topologyKeys":[]}` | ----------------------------------------------------------------------------- # |
| podAnnotations | object | `{}` |  |
| postgresql | object | `{"enabled":true,"global":{"postgresql":{"auth":{"postgresPassword":"postgresql"}}},"primary":{"initdb":{"scripts":{"featurehub.sql":"CREATE USER featurehub PASSWORD 'featurehub' LOGIN;\nCREATE DATABASE featurehub;\nGRANT ALL PRIVILEGES ON DATABASE featurehub TO featurehub;\n\\connect featurehub\nGRANT ALL ON SCHEMA public TO featurehub;"}},"persistence":{"accessModes":["ReadWriteOnce"],"enabled":true,"size":"128Mi","storageClassName":"standard"}}}` | ----------------------------------------------------------------------------- # |
