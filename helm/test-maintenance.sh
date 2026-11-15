#!/bin/bash
# Checks the maintenance window and Redis fallback rendering of the chart. Needs helm and yq (mikefarah, v4).
#
# The important invariant: the Dacha2 and Edge pod templates must be identical in every maintenance mode and whether
# Redis is on or off, because a pod template change restarts them (and restarting Dacha2 empties its cache).
set -euo pipefail
cd "$(dirname "$0")"

FAILED=0
TIMES="maintenance.start=2026-11-17T10:00:00Z,maintenance.end=2026-11-17T12:30:00Z,maintenance.message=Upgrading"
REDIS="redis.url=rediss://10.0.0.3:6378,redis.password=s3cr\\\\et,redis.keyPrefix=fh"

render() {
  helm template featurehub featurehub -f test-values.yaml "$@"
}

# select one document by kind and name
doc() {
  yq "select(.kind == \"$1\" and .metadata.name == \"$2\")"
}

pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; FAILED=1; }

expect_eq() { # description expected actual
  if [ "$2" == "$3" ]; then pass "$1"; else fail "$1: expected [$2] got [$3]"; fi
}

expect_render_fails() { # description message-fragment args...
  local desc=$1 frag=$2; shift 2
  local out
  if out=$(render "$@" 2>&1); then
    fail "$desc: render succeeded"
  elif echo "$out" | grep -q "$frag"; then
    pass "$desc"
  else
    fail "$desc: wrong error: $out"
  fi
}

BASE_DACHA=$(render | doc Deployment featurehub-dacha | yq '.spec.template')
BASE_EDGE=$(render | doc Deployment featurehub-edge | yq '.spec.template')

for mode in disabled warm active shutdown post; do
  for redis in off on; do
    args=(--set "maintenance.mode=$mode,$TIMES")
    [ "$redis" == "on" ] && args+=(--set "$REDIS")
    out=$(render "${args[@]}")

    expect_eq "$mode/redis $redis: dacha pod template unchanged" "$BASE_DACHA" \
      "$(echo "$out" | doc Deployment featurehub-dacha | yq '.spec.template')"
    expect_eq "$mode/redis $redis: edge pod template unchanged" "$BASE_EDGE" \
      "$(echo "$out" | doc Deployment featurehub-edge | yq '.spec.template')"

    replicas=$(echo "$out" | doc Deployment featurehub-management-repository | yq '.spec.replicas')
    responder=$(echo "$out" | doc Deployment featurehub-maintenance-responder | yq '.metadata.name')
    backend=$(echo "$out" | doc Ingress featurehub | yq '.spec.rules[0].http.paths[] | select(.path == "/") | .backend.service.name')
    blocked=$(echo "$out" | doc ConfigMap featurehub-edge-update-block | yq '.data.blocked')

    case $mode in
      disabled) e_replicas=1; e_responder=null; e_backend=featurehub-management-repository; e_blocked=null ;;
      warm)     e_replicas=1; e_responder=featurehub-maintenance-responder; e_backend=featurehub-management-repository; e_blocked=null ;;
      active|post) e_replicas=1; e_responder=featurehub-maintenance-responder; e_backend=featurehub-maintenance-responder; e_blocked="Tue, 17 Nov 2026 12:30:00 GMT" ;;
      shutdown) e_replicas=0; e_responder=featurehub-maintenance-responder; e_backend=featurehub-maintenance-responder; e_blocked="Tue, 17 Nov 2026 12:30:00 GMT" ;;
    esac
    expect_eq "$mode/redis $redis: MR replicas" "$e_replicas" "$replicas"
    expect_eq "$mode/redis $redis: responder deployed" "$e_responder" "$responder"
    expect_eq "$mode/redis $redis: ingress / backend" "$e_backend" "$backend"
    expect_eq "$mode/redis $redis: edge update block" "$e_blocked" "$blocked"
  done
done

# the MR ingress (user-defined hosts) also switches
out=$(render --set "maintenance.mode=active,$TIMES,managementRepository.ingress.enabled=true,managementRepository.ingress.hosts[0].host=fh.example.com,managementRepository.ingress.hosts[0].paths[0].path=/,managementRepository.ingress.hosts[0].paths[0].pathType=Prefix")
expect_eq "active: MR ingress backend" featurehub-maintenance-responder \
  "$(echo "$out" | doc Ingress featurehub-management-repository | yq '.spec.rules[0].http.paths[0].backend.service.name')"

# the responder gets the window and the MR port
out=$(render --set "maintenance.mode=warm,$TIMES")
responder_env=$(echo "$out" | doc Deployment featurehub-maintenance-responder | yq -o=json '.spec.template.spec.containers[0].env | map({"key": .name, "value": .value}) | from_entries' -I0)
expect_eq "responder env" '{"server.port":"8085","monitor.port":"8701","run.nginx":"true","web.asset.location":"/var/www/html/intranet","maintenance.start":"2026-11-17T10:00:00Z","maintenance.end":"2026-11-17T12:30:00Z","maintenance.message":"Upgrading"}' "$responder_env"

# announcing a window while disabled: MR gets the env, nothing else changes
out=$(render --set "$TIMES")
expect_eq "disabled with times: MR gets maintenance.end" "2026-11-17T12:30:00Z" \
  "$(echo "$out" | doc Deployment featurehub-management-repository | yq '.spec.template.spec.containers[0].env[] | select(.name == "maintenance.end") | .value')"

# redis on MR
out=$(render --set "$REDIS" --set-file redis.caCert=<(printf -- '-----BEGIN CERTIFICATE-----\nabc\n-----END CERTIFICATE-----\n'))
mr=$(echo "$out" | doc Deployment featurehub-management-repository)
expect_eq "redis: MR redis.url" "rediss://10.0.0.3:6378" "$(echo "$mr" | yq '.spec.template.spec.containers[0].env[] | select(.name == "redis.url") | .value')"
expect_eq "redis: MR password secretKeyRef" "featurehub-mr-redis/password" "$(echo "$mr" | yq '.spec.template.spec.containers[0].env[] | select(.name == "redis.password") | .valueFrom.secretKeyRef.name + "/" + .valueFrom.secretKeyRef.key')"
expect_eq "redis: MR CA mounted" "/etc/redis-ca" "$(echo "$mr" | yq '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "redis-ca") | .mountPath')"
expect_eq "redis: MR has redis checksum" "true" "$(echo "$mr" | yq '.spec.template.metadata.annotations | has("checksum/redis")')"
expect_eq "redis: MR secret" '"s3cr\\et"' "$(echo "$out" | doc Secret featurehub-mr-redis | yq -o=json '.stringData.password')"
props=$(echo "$out" | doc ConfigMap featurehub-dacha-redis | yq '.data["redis.properties"]')
cafile=$(echo "$out" | doc ConfigMap featurehub-dacha-redis | yq '.data | keys | .[] | select(test("^ca-"))')
expect_eq "redis: dacha properties" "# managed by helm - dacha2 re-reads this file at runtime
dacha2.redis.url=rediss://10.0.0.3:6378
dacha2.redis.mode=standalone
dacha2.redis.key-prefix=fh
dacha2.redis.tls.ca-cert=/etc/redis-config/$cafile" "$props"
expect_eq "redis: dacha secret escapes backslash" "# managed by helm - dacha2 re-reads this file at runtime
dacha2.redis.password=s3cr\\\\et" "$(echo "$out" | doc Secret featurehub-dacha-redis | yq '.stringData["redis.properties"]')"

# redis on MR only (enable MR first): dacha files stay empty
out=$(render --set "$REDIS,redis.dacha.enabled=false")
expect_eq "redis mr only: dacha properties empty" "# managed by helm - dacha2 re-reads this file at runtime" \
  "$(echo "$out" | doc ConfigMap featurehub-dacha-redis | yq '.data["redis.properties"]')"

# existing secret
out=$(render --set "redis.url=redis://redis:6379,redis.existingSecret=my-redis")
expect_eq "existingSecret: no chart secrets" "" "$(echo "$out" | yq 'select(.kind == "Secret" and (.metadata.name | test("redis"))) | .metadata.name')"
expect_eq "existingSecret: dacha mounts it" "my-redis" "$(echo "$out" | doc Deployment featurehub-dacha | yq '.spec.template.spec.volumes[] | select(.name == "redis-secret") | .secret.secretName')"
expect_eq "existingSecret: MR uses it" "my-redis/password" "$(echo "$out" | doc Deployment featurehub-management-repository | yq '.spec.template.spec.containers[0].env[] | select(.name == "redis.password") | .valueFrom.secretKeyRef.name + "/" + .valueFrom.secretKeyRef.key')"

# update block off
out=$(render --set "maintenance.edgeUpdateBlock.enabled=false")
expect_eq "update block off: no configmap" "null" "$(echo "$out" | doc ConfigMap featurehub-edge-update-block | yq '.metadata.name')"
expect_eq "update block off: no edge env" "null" "$(echo "$out" | doc Deployment featurehub-edge | yq '.spec.template.spec.containers[0].env')"

# validation
expect_render_fails "bad mode" "maintenance.mode must be one of" --set maintenance.mode=on
expect_render_fails "missing times" "requires maintenance.start" --set maintenance.mode=warm
expect_render_fails "time without Z" "ISO-8601 UTC timestamp" --set "maintenance.start=2026-11-17T10:00:00"
expect_render_fails "time with offset" "ISO-8601 UTC timestamp" --set "maintenance.end=2026-11-17T10:00:00+13:00"
expect_render_fails "impossible date" "not a real date" --set "maintenance.end=2026-02-31T10:00:00Z"
expect_render_fails "bad redis mode" "redis.mode must be one of" --set "redis.mode=single"
expect_render_fails "sentinel without master" "redis.sentinelMaster is required" --set "redis.url=redis://a:1,redis.mode=sentinel"
expect_render_fails "password and existingSecret" "only one of" --set "redis.password=a,redis.existingSecret=b"

if [ $FAILED -ne 0 ]; then
  echo "maintenance tests FAILED"
  exit 1
fi
echo "maintenance tests passed"
