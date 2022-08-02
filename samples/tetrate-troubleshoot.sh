export CONTAINER_IMAGE="gcr.io/r150test6-us-east1/tetrate-troubleshoot:1.4.7"
alias ttshoot="kubectl run tmp-shell --rm -i --tty --image $CONTAINER_IMAGE"
ttshoot -n istio-system
