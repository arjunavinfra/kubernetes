#!/bin/bash 
istioctl operator init  
istioctl apply -f profile.yaml -y

STATUS=`kubectl get iop -A  | awk '{prinet $4}'`
if [ "${STATUS}" == 'HEALTHY' ]; then
    echo -e "\n 🔹The pod status is healthy now 🎉"
    break
fi
echo -e "\n 🔹Waiting the istiod status  to become 1/1 ⏰"

sleep 4

echo -e "\n  🔹The pod status must be  healthy now 🎉"
echo -e "\n"
kubectl get po -n istio-system

echo -e "\n 🔹Injecting label to default namespace 💉"
echo -e "\n"
kubectl label ns default istio-injection=enabled 

kubectl get ns -L istio-injection 


echo -e "\n 🔹Applying addone 🛒"

kubectl apply -f ./addone > /dev/null

echo -e "\n 🔹Installation completed 🎌"
echo -e "\n"