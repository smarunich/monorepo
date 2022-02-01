export POD="bookinfo-ratings1"
export NAMESPACE="bookinfo"

kubectl port-forward -n $NAMESPACE $POD 15000:15000
curl -X POST http://localhost:15000/logging\?level\=trace
