#!/bin/bash
set -x
set -e

export KUBECONFIG=~/.kube/topics-test

minikube start

kubectl cluster-info

minikube addons enable ingress

kubectl create -f demo-k8s

REPONAME=topics01
kubectl exec -c svn svn-0 -- repocreate $REPONAME -o daemon
# first repo access should be through apache to avoid rep-cache write issue at commit
curl -u "reposetup:" http://$(minikube ip)/svn/$REPONAME/ | grep rev
# indexing doesn't re-run repo discovery
kubectl exec -c indexing svn-0 -- kill 1
