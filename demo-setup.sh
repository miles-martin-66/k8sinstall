#!/bin/bash
kubectl apply -f haproxy-ingress.yaml
kubectl apply -f haproxy-demo.yaml
kubectl apply -f ingress-object.yaml
#kubectl run -i --tty busybox -n haproxy-demo --image=busybox

