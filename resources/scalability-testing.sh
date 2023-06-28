#!/bin/bash

cd $(dirname ${BASH_SOURCE})
set -e

for i in $(seq 1 30)
do
    cp example.cronjob.yaml example.cronjob.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.cronjob.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.cronjob.${i}.yaml
    rm example.cronjob.${i}.yaml

    cp example.csr.yaml example.csr.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.csr.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.csr.${i}.yaml
    rm example.csr.${i}.yaml

    cp example.daemonset.yaml example.daemonset.${i}.yaml
    sed -i "s/name: example/name: example${i}/" example.daemonset.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.daemonset.${i}.yaml
    rm example.daemonset.${i}.yaml

    cp example.deployment.yaml example.deployment.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.deployment.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.deployment.${i}.yaml
    rm example.deployment.${i}.yaml

    cp example.job.yaml example.job.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.job.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.job.${i}.yaml
    rm example.job.${i}.yaml

    cp example.mwc.yaml example.mwc.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.mwc.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.mwc.${i}.yaml
    rm example.mwc.${i}.yaml

    cp example.pod.yaml example.pod.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.pod.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.pod.${i}.yaml
    rm example.pod.${i}.yaml

    cp example.vwc.yaml example.vwc.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.vwc.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.vwc.${i}.yaml
    rm example.vwc.${i}.yaml

    cp example.service.yaml example.service.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.service.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.service.${i}.yaml
    rm example.service.${i}.yaml

    cp example.statefulset.yaml example.statefulset.${i}.yaml
    sed -i "s/name: example/name: example-${i}/" example.statefulset.${i}.yaml
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @example.statefulset.${i}.yaml
    rm example.statefulset.${i}.yaml
done

CRDS="crds/*"
for f in $CRDS
do
    curl -X POST http://127.0.0.1:5000/clients/client01/resources --data-binary @${f}
done

