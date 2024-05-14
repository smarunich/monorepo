kubectl create ns httpbingo
kubectl label ns httpbingo istio-injection=enabled
helm repo add estahn https://estahn.github.io/charts
helm install httpbingo estahn/httpbingo -n httpbingo
export HTTPBINGO_POD=$(kubectl get pods --namespace httpbingo -l app.kubernetes.io/instance=httpbingo -o jsonpath='{.items[0].metadata.name}')

kubectl create ns fortio
kubectl label ns fortio istio-injection=enabled
helm repo add rgnu https://gitlab.com/mulesoft-int/helm-repository/-/raw/master/ 
helm install fortio rgnu/istio-fortio -n fortio

export FORTIO_POD=$(kubectl get pods -n fortio -l app=fortio -l version=v1 -o 'jsonpath={.items[0].metadata.name}')
kubectl exec "$FORTIO_POD" -n fortio -c fortio -- /usr/bin/fortio curl -quiet http://httpbingo.httpbingo:80/get
kubectl exec "$FORTIO_POD" -n fortio -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbingo.httpbingo:80/get

# 1 second delay
kubectl exec "$FORTIO_POD" -n fortio -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbingo.httpbingo:80/delay/1

# 50% error rate
kubectl exec "$FORTIO_POD" -n fortio -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbingo.httpbingo:80/unstable\?failure_rate=0.5

# 100% error rate
kubectl exec "$FORTIO_POD" -n fortio -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbingo.httpbingo:80/unstable\?failure_rate=1
