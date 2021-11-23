#!/bin/bash

export NEO4J_VERSION=4.3.6
export CORE_NUMBER=3
export REPLICA_NUMBER=0

export cluster_members=""

for i in $(seq 1 $CORE_NUMBER)
do
   pod_name=neo4j-core${i}
   cluster_members+=${pod_name}.neo4jdb-cluster-service.default.svc.cluster.local:5000 
   if [ $i -lt ${CORE_NUMBER} ]; then
       cluster_members+=,
   fi
   cat <<EOF > core${i}-pod.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${pod_name}
  labels:
    app: neo4jdb
    role: core
spec:
  replicas: 1
  selector:
    matchLabels:
      app: neo4jdb
      role: core
  template:
    metadata:
      labels:
        app: neo4jdb
        role: core
    spec:
      hostname: ${pod_name}
      subdomain: neo4jdb-cluster-service
      containers:
      - name: ${pod_name}
        image: "neo4j:${NEO4J_VERSION}-enterprise"
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        ports:
        - containerPort: 7474
          name: browser
        - containerPort: 7687
          name: bolt
        - containerPort: 5000
          name: discovery
        - containerPort: 6000
          name: transaction
        - containerPort: 7000
          name: raft
        envFrom:
        - configMapRef:
            name: ${pod_name}-configmap
        - configMapRef:
            name: neo4j-core-configmap
EOF
    cat <<EOF > ${pod_name}-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${pod_name}-configmap
  namespace: default
data:
  NEO4J_dbms_default__advertised__address: ${pod_name}.neo4jdb-cluster-service.default.svc.cluster.local
EOF
done
