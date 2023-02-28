# JAX 'Hello World' on GKE + A100


> **🧪 Preview:** This repository contains assets in development. Should not be used in a production system.

## Goal

This repository contains instructions to create a GKE cluster in Google Cloud 
connected to 8 NVIDIA A100 40G GPUs and run a JAX example as a K8s Job on the GPUs.

### Prerequisites

- A GCP Project with billing setup
- Docker and kubectl installed in the machine where you are running these steps

## Getting Started

### Preparing GKE cluster

- Enable the required APIs

```
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
```

- (If not created with the project) Create default VPC network

```
   gcloud compute networks create default \
    --subnet-mode=auto \
    --bgp-routing-mode=regional \
    --mtu=1460
```

- Create a GKE cluster (for the control plane)

```
   gcloud container clusters create jax-example \
    --zone=us-central1-b
```

- Create a Node Pool where the GPUs will be attached.
This Node Pool will have a single `a2-highgpu-8g` node, which has
8 A100 40Gb GPUs attached to it. 

> For the purpose of this demo, you will be using a preemptible node,
which has a lower cost, and also does not require GPU quota increase
for your project.

> Detailed steps to [create a GKE cluster with gVNIC](https://cloud.google.com/kubernetes-engine/docs/how-to/using-gvnic)

> General guide to [use GPUs on GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus) 

```
   gcloud container node-pools create gpus-node-pool \
    --machine-type=a2-highgpu-8g --cluster=jax-example \
    --enable-gvnic --zone=us-central1-b \
    --num-nodes=1 --preemptible
```

- Install NVIDIA drivers on the cluster

```
   kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml
```

### Packaging JAX code in a container

You can review the JAX code included in `train.py`

- Build the container image and push to the project's container registry

```
   export PROJECT=$(gcloud config list project --format "value(core.project)")

   docker build . -f Dockerfile -t "gcr.io/${PROJECT}/jax-container:latest"

   docker push "gcr.io/${PROJECT}/jax-container:latest"
```

> The container image is big. These steps might take a few minutes to complete.

### Launch the JAX container 

The yaml files in the `kubernetes` folder have all the configuration needed to run 
the JAX code as a Kubernetes Job.

- Deploy the components in the GKE cluster you created

```
   cd kubernetes
   kubectl apply -f .
```



## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.
