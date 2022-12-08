#!/bin/bash 
istioctl operator init  
istioctl apply -f profile.yaml -y
kubectl get iop -A 
kubectl get po -n istio-system
kubectl label ns default istio-injection=enabled
kubectl get ns -L istio-injection 

kubectl apply -f ./addone 