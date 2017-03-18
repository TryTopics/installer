#!/bin/bash

export KUBECONFIG=~/.kube/topics-test

minikube start

kubectl cluster-info

minikube addons enable ingress

kubectl create -f demo-k8s

kubectl exec -c svn svn-0 -- repocreate topics01 -o daemon
