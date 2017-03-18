#!/bin/bash
set -x
set -e

# Encourage the habit of environment specific kubeconfig, with no live cluster in default
# export KUBECONFIG=~/.kube/topics-test
[ -z "$KUBECONFIG" ] && echo "Bailing out because you're running a fallback kubeconfig" && exit 1

NAMESPACE="topics"
CONTEXT=$(kubectl config view | grep current-context | awk '{print $2}')
kubectl config set-context $CONTEXT --namespace=$NAMESPACE
echo "namespace \"$NAMESPACE\" set."

minikube start

kubectl cluster-info

minikube addons enable ingress

kubectl create -f demo-k8s/

# curl will retry on 503, but not prior to that as the machine doesn't respond
sleep 30
curl -u reposetup: --retry 60 --retry-delay 5 http://$(minikube ip)/svn/ -I 2>&1 | grep "HTTP"

REPONAME=topics01
kubectl exec -c svn svn-0 -- repocreate $REPONAME -o daemon
# first repo access should be through apache to avoid rep-cache write issue at commit
curl -u "reposetup:" http://$(minikube ip)/svn/$REPONAME/ -k | grep rev
# indexing doesn't re-run repo discovery
kubectl exec -c indexing svn-0 -- kill 1
