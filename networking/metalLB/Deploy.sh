
echo -e "\n 🔹Installing metalLB   🚜"
echo -n " "
kubectl apply -f metallb-native.yaml  > /dev/null
echo -n " "
echo -e"\n 🔹Waithing the pod to be in ready state   ⏳"
echo -n " "

kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                -l component=controller \
                --timeout=90s
                
docker network inspect -f '{{.IPAM.Config}}' kind > /dev/null

network=`docker network inspect -f '{{.IPAM.Config}}' kind | sed -n '/\(\(1\?[0-9][0-9]\?\|2[0-4][0-9]\|25[0-5]\)\.\)\{3\}\(1\?[0-9][0-9]\?\|2[0-4][0-9]\|25[0-5]\)/p' | sed 's/\[{//g' | awk  '{ print $1 " " $2 }' | cut -d "." -f -2`
echo -n " "
echo -e "\n 🔹Assigning IP Address   ⛽"
echo -n " "

cat IPassign.yaml | sed "s|IPADDR|$network|g" | kubectl apply -f -

echo ""

