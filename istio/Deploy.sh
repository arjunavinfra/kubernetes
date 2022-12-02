#!/bin/bash 


if [ -f ${pwd}/istio/istio-*/bin/istioctl ]; then 
echo "Istio is already installed!!!"
istioctl version ;  istioctl verify-install
else

curl -L https://istio.io/downloadIstio | sh -
echo export PATH="$PATH:/home/arjun/Documents/kubernetes/istio/istio-1.16.0/bin" >> $HOME/.bashrc
source $HOME/.bashrc

istioctl version ;  istioctl verify-install


fi 


# install the configuration profile
# $ istioctl install --set profile=demo -y

# Inject sidecar 
# kubectl label namespace default istio-injection=enabled (side car proxy will be added with each pod)

kubectl rollout restart dpeloyment ----- if not get 2/2