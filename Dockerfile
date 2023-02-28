ARG FROM_IMAGE_NAME=nvcr.io/nvidia/tensorflow:22.08-tf2-py3
FROM ${FROM_IMAGE_NAME}

# Install the latest jax
RUN pip install --upgrade pip
RUN pip install jax[cuda]==0.4.1 -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

WORKDIR /scripts
ADD train.py /scripts