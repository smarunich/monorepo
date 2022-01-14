export FOLDER='.'

cat >"${FOLDER}/productpage_patch.yaml" <<EOF
spec:
  template:
    spec:
      containers:
      - name: productpage
        image: docker.io/chirauki/productpage
        env:
        - name: DETAILS_HOSTNAME
          value: details.tetrate.com
        - name: DETAILS_SERVICE_PORT
          value: 80
      
EOF

kubectl -n $TIER2_NS patch deployments.apps/productpage-v1 --patch "$(cat "$FOLDER"/templates/productpage_patch.yaml)" >/dev/null 2>/dev/null
