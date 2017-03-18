#!/bin/bash
set -x
set -e

# Encourage the habit of environment specific kubeconfig, with no live cluster in default
# export KUBECONFIG=~/.kube/topics-test
[ -z "$KUBECONFIG" ] && echo "Bailing out because you're running a fallback kubeconfig" && exit 1

minikube start

NAMESPACE="topics"
CONTEXT=$(kubectl config view | grep current-context | awk '{print $2}')
kubectl config set-context $CONTEXT --namespace=$NAMESPACE
echo "namespace \"$NAMESPACE\" set."

sleep 5
kubectl cluster-info

minikube addons enable ingress

kubectl create -f demo-k8s/

# Minikube will only manage to bind the volume if it is created after the StatefulSet
kubectl delete -f demo-k8s/backend-rweb-pvc.yml
sleep 30
kubectl create -f demo-k8s/backend-rweb-pvc.yml

# curl will retry on 503, but not prior to that as the machine doesn't respond
sleep 60
curl -u reposetup: --retry 60 --retry-delay 5 http://$(minikube ip)/svn/ -I 2>&1 | grep "HTTP"

REPONAME=topics01
kubectl -n $NAMESPACE exec -c svn svn-0 -- repocreate $REPONAME -o daemon
# first repo access should be through apache to avoid rep-cache write issue at commit
curl -u "reposetup:" http://$(minikube ip)/svn/$REPONAME/ -k | grep rev
# indexing doesn't re-run repo discovery
kubectl -n $NAMESPACE exec -c indexing svn-0 -- kill 1
