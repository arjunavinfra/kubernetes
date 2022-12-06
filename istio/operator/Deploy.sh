#!/bin/bash -x
# istioctl operator init --watchedNamespaces=default

# kubectl wait --namespace istio-operator \
#                 --for=condition=ready pod \
#                 --selector=app=metallb \
#                 --timeout=90s

# kubectl apply -f bookinfo-app.yaml
# kubectl label namespace default istio-injection=enabled
# kubectl rollout restart deployment 

# kubectl wait --namespace default \
#                 --for=condition=ready pod \
#                 --selector=env=kubex \
#                 --timeout=90s

# kubectl apply -f virtual-service-all-v1.yaml

kubectl apply -f ./*.yaml 


kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
