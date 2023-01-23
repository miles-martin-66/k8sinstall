# k8sinstall
This Package contains scripts to build a K8s node on Debian 11 running on x86 or Raspbery PI arm hardware.
Also contained are two scripts demo-setup.sh and demo-teardown.sh that build a working web service and
HAProxy ingress controller environment.

The Calico CNI will be installed along with MetalLB.  MetalLB will manage the raising and lowering of 
public IP addresses for the cluster.  Calico can be used to manage BGP routing if required.  


Follow these instructions to build a working k8s node for a Debian 11 x86.

Prerequisites: Your hardware or vm will need 8GB RAM, 20GB diskspace, 4 cores
loged in as 'root', run:

$ ./k8s-deb11-install.sh

Follow these instructions to build a working k8s node for a Debian 11 on a raspberry PI 4.

Prerequisites: Your hardware or vm will need 8GB RAM, 20GB diskspace, 4 cores
loged in as 'root', run:

$ ./k8s-rpi4-install.sh

If you are creating a cluster simply perform the same process on other servers/VMs and the 'join' those
nodes to your cluster.

Once your cluster is built and working,  dploy the demo app by simply running the demo-setup.sh script:

$ ./demo-setup.sh

This will bild a web service app running on NGINX which returns a simple webpage.  It also deploys the 
HAProxy ingress controler and an ingress object that 'connects' the controler with the service.

To teardown the demo,  run:

$ ./demo-teardown.sh 
 



