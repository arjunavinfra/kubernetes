#!/bin/bash 

if [  -f /usr/local/bin/istioctl  ]; then 
echo "Istio is already installed!!!"
 istioctl x precheck
 istioctl version ;  istioctl verify-install
else

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.16.0 TARGET_ARCH=x86_64 sh -


sudo mv istio-1.16.0/bin/istioctl /usr/local/bin/istioctl 

istioctl version ;  istioctl verify-install

istioctl x precheck

fi 

while true; do
    read -p "Do you wish to install istio demo profile program........? " yn
    case $yn in
        [Yy]* ) istioctl install --set profile=demo -y; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done



# install the configuration profile
# $ istioctl install --set profile=demo -y

# Inject sidecar 
# kubectl label namespace default istio-injection=enabled (side car proxy will be added with each pod)

# kubectl rollout restart dpeloyment ----- if not get 2/2

#  istioctl dashboard kiali

#  istio gateway is hanling inbod and outbond traffic on istion 

#  istio gateway = istion igress GW + istiod + istio egress GW


#  kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}'


# kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}'


 curl -s -HHost:bookinginfo.app  http://172.18.255.200/productpage