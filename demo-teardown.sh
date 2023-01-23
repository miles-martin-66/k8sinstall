#!/bin/bash
kubectl delete namespace haproxy-demo
kubectl delete namespace haproxy-controller
kubectl delete clusterrole.rbac.authorization.k8s.io/haproxy-kubernetes-ingress
kubectl delete clusterrolebinding.rbac.authorization.k8s.io/haproxy-kubernetes-ingress


