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
  ----    ------     ----  ----               -------
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



