
kubectl apply -f ingress-operator.yaml

echo "Waithing the pod to be in ready state....!!!!!!"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
