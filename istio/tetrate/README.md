#Lab: Installing Istio
In this lab, we will install Istio on your Kubernetes cluster using the Istio operator.

Prerequisites
To install Istio, we will need a running instance of a Kubernetes cluster. All cloud providers have a managed Kubernetes cluster offering we can use to install Istio service mesh.

We can also run a Kubernetes cluster locally on your computer using one of the following platforms:

Minikube
Docker Desktop
kind
MicroK8s
When using a local Kubernetes cluster, ensure your computer meets the minimum requirements for Istio installation (e.g., 16384 MB RAM and 4 CPUs). Also, ensure the Kubernetes cluster version is v1.19.0 or higher.

Kubernetes CLI
If you need to install the Kubernetes CLI, follow these instructions.

We can run kubectl version to check if the CLI got installed. You should see the output similar to this one:

$ kubectl version
Client Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.2", GitCommit:"f5743093fd1c663cb0cbc89748f730662345d44d", GitTreeState:"clean", BuildDate:"2020-09-16T21:51:49Z", GoVersion:"go1.15.2", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.0", GitCommit:"e19964183377d0ec2052d1f1fa930c4d7575bd50", GitTreeState:"clean", BuildDate:"2020-08-26T14:23:04Z", GoVersion:"go1.15", Compiler:"gc", Platform:"linux/amd64"}
Download Istio
Throughout this course, we will be using Istio 1.10.3. The first step to installing Istio is downloading the Istio CLI (istioctl), installation manifests, samples, and tools.

The easiest way to install the latest version is to use the downloadIstio script. Open a terminal window and open the folder where you want to download Istio, then run the download script:

$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.10.3 sh -
Istio release is downloaded and unpacked to the folder called istio-1.10.3. To access istioctl we should add it to the path:

$ cd istio-1.10.3
$ export PATH=$PWD/bin:$PATH
To check istioctl is on the path, run istioctl version. You should see an output like this:

$ istioctl version
no running Istio pods in "istio-system"
1.10.3
Install Istio
Istio supports multiple configuration profiles. The difference between the profiles is in components that get installed.

$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    external
    minimal
    openshift
    preview
    remote
The recommended profile for production deployments is the default profile. We will be installing the demo profile as it contains all core components, has a high level of tracing and logging enabled, and is meant for learning about different Istio features.

We can also start with the minimal component and individually install other features, like ingress and egress gateway, later.

Because we will use the Istio operator for installation, we have to deploy the operator first.

To deploy the Istio operator, run:

$ istioctl operator init
Installing operator controller in namespace: istio-operator using image: docker.io/istio/operator:1.10.3
Operator controller will watch namespaces: istio-system
✔ Istio operator installed                                                                     
✔ Installation complete

The init command creates the istio-operator namespaces and deploys the custom resource definition, operator deployment, and other resources necessary for the operator to work. The operator is ready to use when to installation completes.

To install Istio, we have to create the IstioOperator resource and specify the configuration profile we want to use.

Create a file called demo-profile.yaml with the following contents:

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: demo-istio-install
spec:
  profile: demo

The last thing we need to do is to create the resources:

$ kubectl apply -f demo-profile.yaml  
namespace/istio-system created
istiooperator.install.istio.io/demo-istio-install created
As soon as the operator detects the IstioOperator resource, it will start installing Istio. The whole process can take around 5 minutes.

To check the status of the installation, we can look at the status of the Pods in the istio-system namespace:

$ kubectl get po -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-6db9994577-sn95p    1/1     Running   0          79s
istio-ingressgateway-58649bfdf4-cs4fk   1/1     Running   0          79s
istiod-dd4b7db5-nxrjv                   1/1     Running   0          111s
Or we can check the status of the installation by listing the Istio operator resource. The installation completes once the STATUS column shows HEALTHY:

$ kubectl get iop -A
NAMESPACE      NAME                   REVISION   STATUS        AGE
istio-system   demo-installation                 HEALTHY       67s
The operator has finished installing Istio when all Pods are running, and the operator status is HEALTHY.

Enable sidecar injection
As we’ve learned in the previous section, service mesh needs the sidecar proxies running alongside each application.

To inject the sidecar proxy into an existing Kubernetes deployment, we can use kube-inject action in the istioctl command.

However, we can also enable automatic sidecar injection on any Kubernetes namespace. If we label the namespace with istio-injection=enabled, Istio automatically injects the sidecars for any Kubernetes Pods we create in that namespace.

Let’s enable automatic sidecar injection on the default namespace by adding a label:

$ kubectl label namespace default istio-injection=enabled
namespace/default labeled
To check the namespace is labeled, run the command below. The default namespace should be the only one with the value enabled.

$ kubectl get namespace -L istio-injection
NAME              STATUS   AGE     ISTIO-INJECTION
default           Active   118m    enabled
istio-operator    Active   2m31s   disabled
istio-system      Active   115m    disabled
kube-node-lease   Active   118m
kube-public       Active   118m
kube-system       Active   118m
We can now try creating a Deployment in the default namespace and observe the injected proxy. We will create a deployment called my-nginx with a single container using image nginx:

$ kubectl create deploy my-nginx --image=nginx
deployment.apps/my-nginx created
If we look at the Pods, you will notice there are two containers in the Pod:

$ kubectl get po
NAME                        READY   STATUS    RESTARTS   AGE
my-nginx-6b74b79f57-hmvj8   2/2     Running   0          62s
Similarly, describing the Pod shows Kubernetes created both an nginx container and an istio-proxy container:

$ kubectl describe po my-nginx-6b74b79f57-hmvj8
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----             -------
  Normal  Scheduled  22s   default-scheduler  Successfully assigned default/my-nginx-6b74b79f57-kfw4m to gke-cluster-1-default-pool-7a69a47b-t5tc
  Normal  Pulled     21s   kubelet            Container image "docker.io/istio/proxyv2:1.10.3" already present on machine
  Normal  Created    21s   kubelet            Created container istio-init
  Normal  Started    21s   kubelet            Started container istio-init
  Normal  Pulling    20s   kubelet            Pulling image "nginx"
  Normal  Pulled     16s   kubelet            Successfully pulled image "nginx" in 4.118905898s
  Normal  Created    15s   kubelet            Created container nginx
  Normal  Started    14s   kubelet            Started container nginx
  Normal  Pulled     14s   kubelet            Container image "docker.io/istio/proxyv2:1.10.3" already present on machine
  Normal  Created    14s   kubelet            Created container istio-proxy
  Normal  Started    14s   kubelet            Started container istio-proxy
To remove the deployment, run the delete command:

$ kubectl delete deployment my-nginx
deployment.apps "my-nginx" deleted
Updating the operator
To update the operator, we can use kubectl and apply the updated IstioOperator resource. For example, if we wanted to remove the egress gateway, we could update the IstioOperator resource like this:

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: demo-installation
spec:
  profile: demo
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: false
Save the above YAML to iop-egress.yaml and apply it to the cluster using kubectl apply -f iop-egress.yaml.

If you list the IstioOperator resource, you’ll notice the status has changed to RECONCILING, and once the operator removes the egress gateway, the status changes back to HEALTHY.

Another option for updating the Istio installation is to create separate IstioOperator resources. That way, you can have a resource for the base installation and separately apply different operators using an empty installation profile. For example, here’s how you could create a separate IstioOperator resource that only deploys an internal ingress gateway:

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: internal-gateway-only
  namespace: istio-system
spec:
  profile: empty
  components:
    ingressGateways:
      - namespace: some-namespace
        name: ilb-gateway
        enabled: true
        label:
          istio: ilb-gateway
        k8s:
          serviceAnnotations:
            networking.gke.io/load-balancer-type: "Internal"
Updating and uninstalling Istio
If we want to update the current installation or change the configuration profile, we will need to update the IstioOperator resource deployed earlier.

To remove the installation, we have to delete the IstioOperator, for example:

$ kubectl delete istiooperator -n istio-system demo-istio-install
Once the operator deletes Istio, we can also remove the operator by running:

$ istioctl operator remove
Make sure to delete the IstioOperator resource first before deleting the operator. Otherwise, there might be leftover Istio resources.












#Exposing services using Gateway resource
As part of the Istio installation, we installed the Istio ingress and egress gateways. Both gateways run an instance of the Envoy proxy, and they operate as load balancers at the edge of the mesh. The ingress gateway receives inbound connections, while the egress gateway receives connections going out of the cluster.

Using the ingress gateway, we can apply route rules to the traffic entering the cluster. We can have a single external IP address that points to the ingress gateway and route traffic to different services within the cluster based on the host header.

Ingress and Egress Gateway
Ingress and Egress Gateway
We can configure both gateways using a Gateway resource. The Gateway resource describes the exposed ports, protocols, SNI (Server Name Indication) configuration for the load balancer, etc.

Under the covers, the Gateway resource controls how the Envoy proxy listens on the network interface and which certificates it presents.

Here’s an example of a Gateway resource:

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - dev.example.com
    - test.example.com
The above Gateway resources set up the Envoy proxy as a load balancer exposing port 80 for ingress. The gateway configuration gets applied to the Istio ingress gateway proxy, which we deployed to the istio-system namespace and has the label istio: ingressgateway set. With a Gateway resource, we can only configure the load balancer. The hosts field acts as a filter and will let through only traffic destined for dev.example.com and test.example.com.

To control and forward the traffic to an actual Kubernetes service running inside the cluster, we have to configure a VirtualService with specific hostnames (dev.example.com and test.example.com for example) and then attach the Gateway to it.

Gateway and VirtualServices
Gateway and VirtualServices
The Ingress gateway we deployed as part of the demo Istio installation created a Kubernetes service with the LoadBalancer type that gets an external IP assigned to it, for example:

$ kubectl get svc -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.0.146.214   <none>           80/TCP,443/TCP,15443/TCP                                                     7m56s
istio-ingressgateway   LoadBalancer   10.0.98.7      XX.XXX.XXX.XXX   15021:31395/TCP,80:32542/TCP,443:31347/TCP,31400:32663/TCP,15443:31525/TCP   7m56s
istiod                 ClusterIP      10.0.66.251    <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP                                8m6s
The way the LoadBalancer Kubernetes service type works depends on how and where we’re running the Kubernetes cluster. For a cloud-managed cluster (GCP, AWS, Azure, etc.), a load balancer resource gets provisioned in your cloud account, and the Kubernetes LoadBalancer service will get an external IP address assigned to it. Suppose we’re using Minikube or Docker Desktop. In that case, the external IP address will either be set to localhost (Docker Desktop) or, if we’re using Minikube, it will remain pending, and we will have to use the minikube tunnel command to get an IP address.

In addition to the ingress gateway, we can also deploy an egress gateway to control and filter traffic that’s leaving our mesh.

We can use the same Gateway resource to configure the egress gateway like we configured the ingress gateway. Using the egress gateway allows us to centralize all outgoing traffic, logging, and authorization.




#################################################





#Simple Routing
We can use the VirtualService resource for traffic routing within the Istio service mesh. With a VirtualService we can define traffic routing rules and apply them when the client tries to connect to the service. An example of this would be sending a request to dev.example.com that eventually ends up at the target service.

Let’s look at an example of running two versions (v1 and v2) of the customers application in the cluster. We have two Kubernetes deployments, customers-v1 and customers-v2. The Pods belonging to these deployments either have a label version: v1 or a label version: v2 set.

Routing to Customers
Routing to Customers
We want to configure the VirtualService to route the traffic to the v1 version of the application. The routing to v1 should happen for 70% of the incoming traffic. The 30% of requests should be sent to the v2 version of the application.

Here’s how the VirtualService resource would look like for the above scenario:

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
  - customers.default.svc.cluster.local
  http:
  - name: customers-v1-routes
    route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v1
      weight: 70
  - name: customers-v2-routes
    route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v2
      weight: 30
Under the hosts field, we define the destination host to which the traffic is being sent. In our case, that’s the customers.default.svc.cluster.local Kubernetes service.

The following field is http, and this field contains an ordered list of route rules for HTTP traffic. The destination refers to a service in the service registry and the destination to which the request will be sent after processing the routing rule. The Istio’s service registry contains all Kubernetes services and any services declared with the ServiceEntry resource.

We are also setting the weight on each of the destinations. The weight equals the proportion of the traffic sent to each of the subsets. The sum of all weight should be 100. If we have a single destination, the weight is assumed to be 100.

With the gateways field, we can also specify the gateway names to which we want to bind this VirtualService. For example:

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
    - customers.default.svc.cluster.local
  gateways:
    - my-gateway
  http:
    ...
The above YAML binds the customers-route VirtualService to the gateway named my-gateway. Adding the gateway name to the gateways list in the VirtualService exposes the destination routes through the gateway.

When a VirtualService is attached to a Gateway, only the hosts defined in the Gateway resource will be allowed. The following table explains how the hosts field in a Gateway resource acts as a filter and the hosts field in the VirtualService as a match.

Gateway Hosts	VirtualService Hosts	Behavior
*	customers.default.svc.cluster.local	Traffic is sent through to the VirtualService as * allows all hosts
customers.default.svc.cluster.local	customers.default.svc.cluster.local	Traffic is sent through as the hosts match
hello.default.svc.cluster.local	customers.default.svc.cluster.local	Does not work, hosts don’t match
hello.default.svc.cluster.local	["hello.default.svc.cluster.local", "customers.default.svc.cluster.local"]	Only hello.default.svc.cluster.local is allowed. It will never allow customers.default.svc.cluster.local through the gateway. However, this is still a valid configuration as the VirtualService could be attached to a second Gateway that has *.default.svc.cluster.local in its hosts field




#############################################################



#Subsets and DestinationRule
The destinations also refer to different subsets (or service versions). With subsets, we can identify different variants of our application. In our example, we have two subsets, v1 and v2, which correspond to the two different versions of our customer service. Each subset uses a combination of key/value pairs (labels) to determine which Pods to include. We can declare subsets in a resource type called DestinationRule.

Here’s how the DestinationRule resource looks like with two subsets defined:

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
Let’s look Subsets and DestinationRule
The destinations also refer to different subsets (or service versions). With subsets, we can identify different variants of our application. In our example, we have two subsets, v1 and v2, which correspond to the two different versions of our customer service. Each subset uses a combination of key/value pairs (labels) to determine which Pods to include. We can declare subsets in a resource type called DestinationRule.

Here’s how the DestinationRule resource looks like with two subsets defined:

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
Let’s look at the traffic policies we can set in the DestinationRule.

Traffic Policies in DestinationRule
With the DestinationRule, we can define load balancing configuration, connection pool size, outlier detection, etc., to apply to the traffic after the routing has occurred. We can set the traffic policy settings under the trafficPolicy field. Here are the settings:

Load balancer settings
Connection pool settings
Outlier detection
Client TLS settings
Port traffic policy

Load Balancer Settings
With the load balancer settings, we can control which load balancer algorithm is used for the destination. Here’s an example of the DestinationRule with the traffic policy that sets the load balancing algorithm for the destination to round-robin:

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
We can also set up hash-based load balancing and provide session affinity based on the HTTP headers, cookies, or other request properties. Here’s a snippet of the traffic policy that sets the hash-based load balancing and uses a cookie called ’location` for affinity:

trafficPolicy:
  loadBalancer:
    consistentHash:
      httpCookie:
        name: location
        ttl: 4s
Connection Pool Settings
These settings can be applied to each host in the upstream service at the TCP and HTTP level, and we can use them to control the volume of connections.

Here’s a snippet that shows how we can set a limit of concurrent requests to the service:

spec:
  host: myredissrv.prod.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 50
Outlier Detection
Outlier detection is a circuit breaker implementation that tracks the status of each host (Pod) in the upstream service. If a host starts returning 5xx HTTP errors, it gets ejected from the load balancing pool for a predefined time. For the TCP services, Envoy counts connection timeouts or failures as errors.

Here’s an example that sets a limit of 500 concurrent HTTP2 requests (http2MaxRequests), with not more than ten requests per connection (maxRequestsPerConnection) to the service. The upstream hosts (Pods) get scanned every 5 minutes (interval), and if any of them fails ten consecutive times (consecutiveErrors), Envoy will eject it for 10 minutes (baseEjectionTime).

trafficPolicy:
  connectionPool:
    http:
      http2MaxRequests: 500
      maxRequestsPerConnection: 10
  outlierDetection:
    consecutiveErrors: 10
    interval: 5m
    baseEjectionTime: 10m

Client TLS Settings
Contains any TLS related settings for connections to the upstream service. Here’s an example of configuring mutual TLS using the provided certificates:

trafficPolicy:
  tls:
    mode: MUTUAL
    clientCertificate: /etc/certs/cert.pem
    privateKey: /etc/certs/key.pem
    caCertificates: /etc/certs/ca.pem

Other supported TLS modes are DISABLE (no TLS connection), SIMPLE (originate a TLS connection the upstream endpoint), and ISTIO_MUTUAL (similar to MUTUAL, which uses Istio’s certificates for mTLS).

Port Traffic Policy
Using the portLevelSettings field we can apply traffic policies to individual ports. For example:

trafficPolicy:
  portLevelSettings:
  - port:
      number: 80
    loadBalancer:
      simple: LEAST_CONN
  - port:
      number: 8000
    loadBalancer:
      simple: ROUND_ROBINat the traffic policies we can set in the DestinationRule.

Traffic Policies in DestinationRule
With the DestinationRule, we can define load balancing configuration, connection pool size, outlier detection, etc., to apply to the traffic after the routing has occurred. We can set the traffic policy settings under the trafficPolicy field. Here are the settings:

Load balancer settings
Connection pool settings
Outlier detection
Client TLS settings
Port traffic policy
Load Balancer Settings
With the load balancer settings, we can control which load balancer algorithm is used for the destination. Here’s an example of the DestinationRule with the traffic policy that sets the load balancing algorithm for the destination to round-robin:

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2

We can also set up hash-based load balancing and provide session affinity based on the HTTP headers, cookies, or other request properties. Here’s a snippet of the traffic policy that sets the hash-based load balancing and uses a cookie called ’location` for affinity:

trafficPolicy:
  loadBalancer:
    consistentHash:
      httpCookie:
        name: location
        ttl: 4s

Connection Pool Settings
These settings can be applied to each host in the upstream service at the TCP and HTTP level, and we can use them to control the volume of connections.

Here’s a snippet that shows how we can set a limit of concurrent requests to the service:

spec:
  host: myredissrv.prod.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 50


Outlier Detection
Outlier detection is a circuit breaker implementation that tracks the status of each host (Pod) in the upstream service. If a host starts returning 5xx HTTP errors, it gets ejected from the load balancing pool for a predefined time. For the TCP services, Envoy counts connection timeouts or failures as errors.

Here’s an example that sets a limit of 500 concurrent HTTP2 requests (http2MaxRequests), with not more than ten requests per connection (maxRequestsPerConnection) to the service. The upstream hosts (Pods) get scanned every 5 minutes (interval), and if any of them fails ten consecutive times (consecutiveErrors), Envoy will eject it for 10 minutes (baseEjectionTime).

trafficPolicy:
  connectionPool:
    http:
      http2MaxRequests: 500
      maxRequestsPerConnection: 10
  outlierDetection:
    consecutiveErrors: 10
    interval: 5m
    baseEjectionTime: 10m

Client TLS Settings
Contains any TLS related settings for connections to the upstream service. Here’s an example of configuring mutual TLS using the provided certificates:

trafficPolicy:
  tls:
    mode: MUTUAL
    clientCertificate: /etc/certs/cert.pem
    privateKey: /etc/certs/key.pem
    caCertificates: /etc/certs/ca.pem

Other supported TLS modes are DISABLE (no TLS connection), SIMPLE (originate a TLS connection the upstream endpoint), and ISTIO_MUTUAL (similar to MUTUAL, which uses Istio’s certificates for mTLS).

Port Traffic Policy
Using the portLevelSettings field we can apply traffic policies to individual ports. For example:

trafficPolicy:
  portLevelSettings:
  - port:
      number: 80
    loadBalancer:
      simple: LEAST_CONN
  - port:
      number: 8000
    loadBalancer:
      simple: ROUND_ROBIN



#####################################################################







Resiliency
Resiliency is the ability to provide and maintain an acceptable level of service in the face of faults and challenges to regular operation. It’s not about avoiding failures. It’s responding to them in such a way that there’s no downtime or data loss. The goal for resiliency is to return the service to a fully functioning state after a failure occurs.

A crucial element in making services available is using timeouts and retry policies when making service requests. We can configure both on Istio’s VirtualService.

Using the timeout field, we can define a timeout for HTTP requests. If the request takes longer than the value specified in the timeout field, Envoy proxy will drop the requests and mark them as timed out (return an HTTP 408 to the application). The connections remain open unless outlier detection is triggered. Here’s an example of setting a timeout for a route:

...
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  timeout: 10s
...

In addition to timeouts, we can also configure a more granular retry policy. We can control the number of retries for a given request and the timeout per try as well as the specific conditions we want to retry on.

Both retries and timeouts happen on the client-side. For example, we can only retry the requests if the upstream server returns any 5xx response code, or retry only on gateway errors (HTTP 502, 503, or 504), or even specify the retriable status codes in the request headers. When Envoy retries a failed request, the endpoint that initially failed and caused the retry is no longer included in the load balancing pool. Let’s say the Kubernetes service has three endpoints (Pods), and one of them fails with a retriable error code. When Envoy retries the request, it won’t resend the request to the original endpoint anymore. Instead, it will send the request to one of the two endpoints that haven’t failed.

Here’s an example of how to set a retry policy for a particular destination:

...
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  retries:
    attempts: 10
    perTryTimeout: 2s
    retryOn: connect-failure,reset
...
The above retry policy will attempt to retry any request that fails with a connect timeout (connect-failure) or if the server does not respond at all (reset). We set the per-try attempt timeout to 2 seconds and the number of attempts to 10. Note that if we set both retries and timeouts, the timeout value will be the maximum the request will wait. If we had a 10-second timeout specified in the above example, we would only ever wait 10 seconds maximum, even if there are still attempts left in the retry policy.

For more details on retry policies, see the x-envoy-retry-on documentation.





##############################################






#Failure Injection
To help us with service resiliency, we can use the fault injection feature. We can apply the fault injection policies on HTTP traffic and specify one or more faults to inject when forwarding the destination’s request.

There are two types of fault injection. We can delay the requests before forwarding and emulate slow network or overloaded service, and we can abort the HTTP request and return a specific HTTP error code to the caller. With the abort, we can simulate a faulty upstream service.

Here’s an example of aborting HTTP requests and returning HTTP 404, for 30% of the incoming requests:

- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  fault:
    abort:
      percentage:
        value: 30
      httpStatus: 404

If we don’t specify the percentage, the Envoy proxy will abort all requests. Note that the fault injection affects services that use that VirtualService. It does not affect all consumers of the service.

Similarly, we can apply an optional delay to the requests using the fixedDelay field:

- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  fault:
    delay:
      percentage:
        value: 5
      fixedDelay: 3s
The above setting will apply 3 seconds of delay to 5% of the incoming requests.

Note that the fault injection will not trigger any retry policies we have set on the routes. For example, if we injected an HTTP 500 error, the retry policy configured to retry on the HTTP 500 will not be triggered.






##############################################







#Advanced Routing
Earlier, we learned how to route traffic between multiple subsets using the proportion of the traffic (weight field). In some cases, pure weight-based traffic routing or splitting is enough. However, there are scenarios and cases where we might need more granular control over how the traffic is split and forwarded to destination services.

Istio allows us to use parts of the incoming requests and match them to the defined values. For example, we can check the URI prefix of the incoming request and route the traffic based on that.

Property	Description
uri	Match the request URI to the specified value
schema	Match the request schema (HTTP, HTTPS, …)
method	Match the request method (GET, POST, …)
authority	Match the request authority header
headers	Match the request headers. Headers have to be lower-case and separated by hyphens (e.g. x-my-request-id). Note, if we use headers for matching, other properties get ignored (uri, schema, method, authority)
Each of the above properties can get matched using one of these methods:

Exact match: e.g. exact: "value" matches the exact string
Prefix match: e.g. prefix: "value" matches the prefix only
Regex match: e.g. regex: "value" matches based on the ECMAscript style regex
For example, let’s say the request URI looks like this: https://dev.example.com/v1/api. To match the request the URI, we’d write it like this:

http:
- match:
  - uri:
      prefix: /v1
The above snippet would match the incoming request, and the request would get routed to the destination defined in that route.

Another example would be using Regex and matching on a header:

http:
- match:
  - headers:
      user-agent:
        regex: '.*Firefox.*'
The above match will match any requests where the User Agent header matches the Regex.

Redirecting and Rewriting Requests
Matching headers and other request properties are helpful, but sometimes we might need to match the requests by the values in the request URI.

For example, let’s consider a scenario where the incoming requests use the /v1/api path, and we want to route the requests to the /v2/api endpoint instead.

The way to do that is to rewrite all incoming requests and authority/host headers that match the /v1/api to /v2/api.

For example:

...
http:
  - match:
    - uri:
        prefix: /v1/api
    rewrite:
      uri: /v2/api
    route:
      - destination:
          host: customers.default.svc.cluster.local
...
Even though the destination service doesn’t listen on the /v1/api endpoint, Envoy will rewrite the request to /v2/api.

We also have the option of redirecting or forwarding the request to a completely different service. Here’s how we could match on a header and then redirect the request to another service:

...
http:
  - match:
    - headers:
        my-header:
          exact: hello
    redirect:
      uri: /hello
      authority: my-service.default.svc.cluster.local:8000
...
The redirect and destination fields are mutually exclusive. If we use the redirect, there’s no need to set the destination.

AND and OR semantics
When doing matching, we can use both AND and OR semantics. Let’s take a look at the following snippet:

...
http:
  - match:
    - uri:
        prefix: /v1
      headers:
        my-header:
          exact: hello
...
The above snippet uses the AND semantics. It means that both the URI prefix needs to match /v1 AND the header my-header has an exact value hello.

To use the OR semantic, we can add another match entry, like this:

...
http:
  - match:
    - uri:
        prefix: /v1
    ...
  - match:
    - headers:
        my-header:
          exact: hello
...
In the above example, the matching will be done on the URI prefix first, and if it matches, the request gets routed to the destination. If the first one doesn’t match, the algorithm moves to the second one and tries to match the header. If we omit the match field on the route, it will continually evaluate true.


############################################


#Bringing external services to the mesh
With the ServiceEntry resource, we can add additional entries to Istio’s internal service registry and make external services or internal services that are not part of our mesh look like part of our service mesh.

When a service is in the service registry, we can use the traffic routing, failure injection, and other mesh features, just like we would with other services.

Here’s an example of a ServiceEntry resource that declares an external API (api.external-svc.com) we can access over HTTPS.

apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc
spec:
  hosts:
    - api.external-svc.com
  ports:
    - number: 443
      name: https
      protocol: TLS
  resolution: DNS
  location: MESH_EXTERNAL
The hosts field can contain multiple external APIs, and in that case, the Envoy sidecar will do the checks based on the hierarchy below. If Envoy cannot inspect any of the items, it moves to the next item in the order.

HTTP Authority header (in HTTP/2) and Host header in HTTP/1.1),
SNI,
IP address and port

Envoy will either blindly forward the request or drop it if none of the above values can be inspected, depending on the Istio installation configuration.

Together with the WorkloadEntry resource, we can handle the migration of VM workloads to Kubernetes. In the WorkloadEntry, we can specify the details of the workload running on a VM (name, address, labels) and then use the workloadSelector field in the ServiceEntry to make the VMs part of Istio’s internal service registry.

For example, let’s say the customers workload is running on two VMs. Additionally, we already have Pods running in Kubernetes with the app: customers label.

Let’s define the WorkloadEntry resources like this:

apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: customers-vm-1
spec:
  serviceAccount: customers
  address: 1.0.0.0
  labels:
    app: customers
    instance-id: vm1
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: customers-vm-2
spec:
  serviceAccount: customers
  address: 2.0.0.0
  labels:
    app: customers
    instance-id: vm2
We can now create a ServiceEntry resource that spans both the workloads running in Kubernetes as well as the VMs:

apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: customers-svc
spec:
  hosts:
  - customers.com
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: customers

With MESH_INTERNAL setting in the location field, we say that this service is part of the mesh. This value is typically used in cases when we include workloads on unmanaged infrastructure (VMs). The other value for this field, MESH_EXTERNAL, is used for external services consumed through APIs. The MESH_INTERNAL and MESH_EXTERNAL settings control how sidecars in the mesh attempt to communicate with the workload, including whether they’ll use Istio mutual TLS by default.



##############################################################


#Sidecar Resource
Sidecar resource describes the configuration of sidecar proxies. By default, all proxies in the mesh have the configuration required to reach every workload in the mesh and accept traffic on all ports.

In addition to configuring the set of ports/protocols proxy accepts when forwarding the traffic, we can restrict the collection of services the proxy can reach when forwarding outbound traffic.

Note that this restriction here is in the configuration only. It’s not a security boundary. You can still reach the services, but Istio will not propagate the configuration for that service to the proxy.

Below is an example of a sidecar proxy resource in the foo namespace that configures all workloads in that namespace to only see the workloads in the same namespace and workloads in the istio-system namespace.

apiVersion:
 networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: foo
spec:
  egress:
    - hosts:
      - "./*"
      - "istio-system/*"
We can deploy a sidecar resource to one or more namespaces inside the Kubernetes cluster. Still, there can only be one sidecar resource per namespace if there’s not workload selector defined.

Three parts make up the sidecar resource, a workload selector, an ingress listener, and an egress listener.

Workload Selector
The workload selector determines which workloads are affected by the sidecar configuration. You can decide to control all sidecars in a namespace, regardless of the workload, or provide a workload selector to apply the configuration only to specific workloads.

For example, this YAML applies to all proxies inside the default namespace, because there’s no selector defined:

apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default-sidecar
  namespace: default
spec:
  egress:
  - hosts:
    - "default/*"
    - "istio-system/*"
    - "staging/*"
The egress section specifies that the proxies can access services running in default, istio-system, and staging namespaces. To apply the resource only to specific workloads, we can use the workloadSelector field. For example, setting the selector to version: v1 will only apply to the workloads with that label set:

apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default-sidecar
  namespace: default
spec:
  workloadSelector:
    labels:
      version: v1
  egress:
  - hosts:
    - "default/*"
    - "istio-system/*"
    - "staging/*"
Ingress and Egress Listener
The ingress listener section of the resource defines which inbound traffic is accepted. Similarly, with the egress listener, you can specify the properties for outbound traffic.

Each ingress listener needs a port set where the traffic will be received (for example, 3000 in the example below) and a default endpoint. The default endpoint can either be a loopback IP endpoint or a Unix domain socket. The endpoint configures where Envoy forwards the traffic.

...
  ingress:
  - port:
      number: 3000
      protocol: HTTP
      name: somename
    defaultEndpoint: 127.0.0.1:8080
...
The above snippet configures the ingress listener to listen on the port 3000 and forward traffic to the loopback IP on the port 8080 where your service is listening to. Additionally, we could set the bind field to specify an IP address or domain socket where we want the proxy to listen for the incoming traffic. Finally, we can use the field captureMode to configure how and if traffic even gets captured.

The egress listener has similar fields, with the addition of the hosts field. With the hosts field, you can specify the service hosts with namespace/dnsName format. For example, myservice.default or default/*. Services specified in the hosts field can be services from the mesh registry, external services (defined with ServiceEntry), or virtual services.

  egress:
  - port:
      number: 8080
      protocol: HTTP
    hosts:
    - "staging/*"
With the YAML above, the sidecar proxies the traffic that’s bound for port 8080 for services running in the staging namespace.



#################################################################################


Envoy Filter
The EnvoyFilter resource allows you to customize the Envoy configuration that gets generated by the Istio Pilot. Using the resource you can update values, add specific filters, or even add new listeners, clusters, etc. Use this feature with care, as incorrect customization might destabilize the entire mesh.

The filters are additively applied, meaning there can be any number of filters for a given workload in a specific namespace. The filters in the root namespace (e.g. istio-system) are applied first, followed by all matching filters in the workloads’ namespace.

Here’s an example of an EnvoyFilter that adds a header called api-version to the request.

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: api-header-filter
  namespace: default
spec:
  workloadSelector:
    labels:
      app: web-frontend
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 8080
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
            subFilter:
              name: "envoy.router"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.lua
        typed_config:
          "@type": "type.googleapis.com/envoy.config.filter.http.lua.v2.Lua"
          inlineCode: |
            function envoy_on_response(response_handle)
              response_handle:headers():add("api-version", "v1")
            end
If you send a request to the $GATEWAY_URL you can notice the api-version header is added, as shown below:

$ curl -s -I -X HEAD  http://$GATEWAY_URL
HTTP/1.1 200 OK
x-powered-by: Express
content-type: text/html; charset=utf-8
content-length: 2471
etag: W/"9a7-hEXE7lJW5CDgD+e2FypGgChcgho"
date: Tue, 17 Nov 2020 00:40:16 GMT
x-envoy-upstream-service-time: 32
api-version: v1
server: istio-envoy