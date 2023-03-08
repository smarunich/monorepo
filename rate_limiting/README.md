# [Rate Limiting](https://docs.tetrate.io/service-bridge/1.6.x/en-us/howto/rate_limiting)

## Enabling the Internal Rate Limiting Server

Review the TSB rate limiting server setup in the docs [here](https://docs.tetrate.io/service-bridge/1.6.x/en-us/howto/rate_limiting/internal_rate_limiting). 

## Setup Prerequisites

### Redis installation

> NOTE: https://bitnami.com/stack/redis/helm

```sh
export REDIS_PASSWORD="RedisTetrate123"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install redis bitnami/redis -n tsb-ratelimit --create-namespace \
  --set architecture=standalone \
  --set auth.password=$REDIS_PASSWORD

cd rate_limitng
oc apply -f redis-enterprise-scc.yaml
oc adm policy add-scc-to-group redis-enterprise-scc system:serviceaccounts:tsb-ratelimit
oc rollout restart statefulset -n tsb-ratelimit
```

Required image:

```
docker.io/bitnami/redis:7.0.9-debian-11-r1
```

### Validate redis deployment

```
❯ oc get all -n tsb-ratelimit
NAME                 READY   STATUS    RESTARTS   AGE
pod/redis-master-0   1/1     Running   0          70s

NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/redis-headless   ClusterIP   None             <none>        6379/TCP   2m
service/redis-master     ClusterIP   172.30.117.145   <none>        6379/TCP   2m

NAME                            READY   AGE
statefulset.apps/redis-master   1/1     2m

❯ oc logs redis-master-0 -n tsb-ratelimit
1:C 07 Mar 2023 19:07:38.408 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C 07 Mar 2023 19:07:38.408 # Redis version=7.0.9, bits=64, commit=00000000, modified=0, pid=1, just started
1:C 07 Mar 2023 19:07:38.408 # Configuration loaded
1:M 07 Mar 2023 19:07:38.409 * monotonic clock: POSIX clock_gettime
1:M 07 Mar 2023 19:07:38.409 * Running mode=standalone, port=6379.
1:M 07 Mar 2023 19:07:38.409 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
1:M 07 Mar 2023 19:07:38.409 # Server initialized
1:M 07 Mar 2023 19:07:38.413 * Reading RDB base file on AOF loading...
1:M 07 Mar 2023 19:07:38.413 * Loading RDB produced by version 7.0.9
1:M 07 Mar 2023 19:07:38.413 * RDB age 263 seconds
1:M 07 Mar 2023 19:07:38.413 * RDB memory usage when created 0.82 Mb
1:M 07 Mar 2023 19:07:38.413 * RDB is base AOF
1:M 07 Mar 2023 19:07:38.413 * Done loading RDB, keys loaded: 0, keys expired: 0.
1:M 07 Mar 2023 19:07:38.413 * DB loaded from base file appendonly.aof.1.base.rdb: 0.000 seconds
1:M 07 Mar 2023 19:07:38.413 * DB loaded from append only file: 0.000 seconds
1:M 07 Mar 2023 19:07:38.413 * Opening AOF incr file appendonly.aof.1.incr.aof on server start
1:M 07 Mar 2023 19:07:38.413 * Ready to accept connections
```


### Enabling the Internal Rate Limiting Server at Tetrate Service Bridge Control Plane

```
kubectl -n istio-system patch controlplane/controlplane --patch="$(cat controlplane_rate_limiting_patch.yaml)"  --type=merge

export REDIS_PASSWORD="RedisTetrate123"

kubectl -n istio-system create secret generic \
  redis-credentials \
  --from-literal=REDIS_AUTH=$REDIS_PASSWORD
```

### Validate ratelimit-server

```sh
❯ k logs -f -l app=ratelimit-server -n istio-system
time="2023-03-07T19:44:03Z" level=warning msg="Listening for debug on '0.0.0.0:6070'"
time="2023-03-07T19:44:03Z" level=warning msg="Listening for HTTP on '0.0.0.0:8080'"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
time="2023-03-07T19:44:03Z" level=warning msg="enabling authentication to redis on redis-master.tsb-ratelimit.svc.cluster.local:6379 without user"
```