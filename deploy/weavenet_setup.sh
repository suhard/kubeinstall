#!/bin/bash

## Apply WeaveNet CNI plugin
## Historical version (RIP WeaveWorks)
## https://thenewstack.io/end-of-an-era-weaveworks-closes-shop-amid-cloud-native-turbulence/
## kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

KUBEVER=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f https://reweave.azurewebsites.net/k8s/net?k8s-version=$KUBEVER
