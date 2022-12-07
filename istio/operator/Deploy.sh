#!/bin/bash -x
istioctl operator init --watchedNamespaces=default  # install crd 


kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istio-install
spec:
  profile: demo
EOF

kubectl get po istio-system

kubectl get iop -A # for checking the operaor rolloedout changes 


kubectl label namespace default istio-injection=enabled


kubectl apply -f bookinfo-app.yaml


kubectl rollout restart deployment 


kubectl apply -f ./*.yaml 


kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# istio delete istiooperaor <name>
# istio remove IstioOperator