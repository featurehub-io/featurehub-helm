# pubsub-emulator

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 398.0.0](https://img.shields.io/badge/AppVersion-398.0.0-informational?style=flat-square)

This is a helm chart for the pubsub emulator, which is useful for testing charts against. It is unsupported, so please do not raise issues against it. We do accept PRs however to improve it if you wish.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | if you want to change the full name |
| global.diskInMb | int | `5` | how much disk space to allocate to the data directory for pubsub to use |
| global.port | int | `8075` | the port to use for pubsub server |
| global.project | string | `"featurehub"` | the name to give to the pubsub server |
| global.replicaCount | int | `1` | how many copies, this should generally only every be 1 but in case there is a need to change it |
| image.pullPolicy | string | `"IfNotPresent"` | image pull policy |
| image.repository | string | `"gcr.io/google.com/cloudsdktool/cloud-sdk"` | repository to pull the emular from |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` | if you need to provide a secret for your repository |
| nameOverride | string | `""` | if you want to change the name |
| podAnnotations | object | `{}` | any annotations you wish to add to the pod |
| podLabels | object | `{}` | any extra labels to give the pod |
| podSecurityContext | object | `{}` | any security context you wish to give the pod |
| resources | object | `{}` |  |
| securityContext | object | `{}` | any overall security context you wish to give |
| service.port | string | `""` | override if you wish to have a different port than that which runs the pod |
| service.type | string | `"ClusterIP"` | what type of IP |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
