
kubectl apply -f metallb-native.yaml

echo "Waithing the pod to be in ready state....!!!!!!"

kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
docker network inspect -f '{{.IPAM.Config}}' kind

network=`docker network inspect -f '{{.IPAM.Config}}' kind | sed -n '/\(\(1\?[0-9][0-9]\?\|2[0-4][0-9]\|25[0-5]\)\.\)\{3\}\(1\?[0-9][0-9]\?\|2[0-4][0-9]\|25[0-5]\)/p' | sed 's/\[{//g' | awk  '{ print $1 " " $2 }' | cut -d "." -f -2`


cat IPassign.yaml | sed "s|IPADDR|$network|g" | kubectl apply -f - 
