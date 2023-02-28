# JAX 'Hello World' on GKE + A100


> **🧪 Preview:** This repository contains assets in development. Should not be used in a production system.

## Goal

This repository contains instructions to create a GKE cluster in Google Cloud 
connected to 8 NVIDIA A100 40G GPUs and run a JAX example as a K8s Job on the GPUs.

### Prerequisites

- A GCP Project with billing setup
- Cloud SDK, docker and kubectl installed in the machine where you are running these steps
- Clone this repo

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

- Change the image name in the `kubernetes/job.yaml` and `kubernetes/kustomization.yaml` files
> Your image name should be something like `gcr.io/<<YOUR_GCP_PROJECT_NAME>>/jax-container:latest`

- Deploy the components in the GKE cluster you created

```
   cd kubernetes
   kubectl apply -k .
```

- Check that the job has been created

```
   kubectl get jobs
```

You should see somehting similar to this:

```
   NAME              COMPLETIONS   DURATION   AGE
jax-hello-world      0/2           5s         5s
```

- Check the Pods that the job has created

```
   kubectl get pods
```

You should see something simlar to this:
```
NAME                      READY   STATUS        RESTARTS   AGE
jax-hello-world-0-s7pwd   0/1     Pending       0          67s
jax-hello-world-1-27z8d   0/1     Pending       0          67s
```

> Be patient, the GKE cluster needs to pull the container image, and this might take a few minutes the first time

- Once the status of the pods is `Running` or `Terminated`, copy tha name of one of the pods and check the logs. 
It contains the output of running the JAX code in `train.py`

```
   kubectl logs jax-hello-world-0-s7pwd
```

If verything goes well, you should see an output similar to this

```
I0228 18:13:44.750335 140410831198016 distributed.py:68] Starting JAX distributed service on 10.76.3.4:1234
I0228 18:13:44.751508 140410831198016 distributed.py:79] Connecting to JAX distributed service on 10.76.3.4:1234
I0228 18:13:44.880263 140410831198016 xla_bridge.py:355] Unable to initialize backend 'tpu_driver': NOT_FOUND: Unable to find driver in registry given worker: 
I0228 18:13:45.414607 140410831198016 xla_bridge.py:355] Unable to initialize backend 'rocm': NOT_FOUND: Could not find registered platform with name: "rocm". Available platform names are: Interpreter CUDA Host
I0228 18:13:45.415148 140410831198016 xla_bridge.py:355] Unable to initialize backend 'tpu': module 'jaxlib.xla_extension' has no attribute 'get_tpu_client'
I0228 18:13:45.415263 140410831198016 xla_bridge.py:355] Unable to initialize backend 'plugin': xla_extension has no attributes named get_plugin_device_client. Compile TensorFlow with //tensorflow/compiler/xla/python:enable_plugin_device set to true (defaults to false) to enable this.
Coordinator host name: jax-hello-world-0.headless-svc
Coordiantor IP address: 10.76.3.4
JAX global devices:[StreamExecutorGpuDevice(id=0, process_index=0, slice_index=0), StreamExecutorGpuDevice(id=1, process_index=0, slice_index=0), StreamExecutorGpuDevice(id=2, process_index=1, slice_index=0), StreamExecutorGpuDevice(id=3, process_index=1, slice_index=0)]
JAX local devices:[StreamExecutorGpuDevice(id=0, process_index=0, slice_index=0), StreamExecutorGpuDevice(id=1, process_index=0, slice_index=0)]
[4. 4.]
Hooray ...
```

## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.
