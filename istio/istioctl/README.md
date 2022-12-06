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

while true  ; do curl -s -HHost:bookinginfo.app  http://172.18.255.200/productpage > /dev/null ; done

 to redirect the traffic into diffrent versions of application we are using the destination rules