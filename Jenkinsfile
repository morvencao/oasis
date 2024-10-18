@Library('ci-shared-lib') _

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        timeout(time: 8, unit: 'HOURS')
    }
     agent {
        docker {
            image 'quay.io/stolostron/acm-qe:go1.22-ginkgo2.20.0'
            registryUrl 'https://quay.io/stolostron/acm-qe'
            registryCredentialsId '0089f10c-7a3a-4d16-b5b0-3a2c9abedaa2'
            args '--network host -u 0:0 -p 3000:3000'
            reuseNode true
        }
    }
    parameters {
        string(name: 'AZURE_REGION', defaultValue: 'eastus', description: 'Region to deploy AKS.')
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Test branch, e.g. main, release-2.y')
        string(name: 'MAESTRO_IMAGE', defaultValue: 'quay.io/morvencao/maestro', description: 'Maestro image to deploy')
        string(name: 'MAESTRO_TAG', defaultValue: 'latest', description: 'Maestro image tag to deploy')
    }
    environment {
        REGION = "${params.AZURE_REGION}"
        USER='acmqe'
        SKIP_CONFIRM = 'true'
        MAESTRO_BASE_IMAGE = "${params.MAESTRO_IMAGE}"
        MAESTRO_TAG = "${params.MAESTRO_TAG}"
        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1 // workaround missing icu lib when run az bicep command
    }
    stages {
        stage('Clean up workspace') {
            steps {
                script {
                    echo "Clean up workspace"
                    sh 'rm -rf aro-hcp maestro'
                }
            }
        }
        stage('Pre-Deploy') {
            steps {
                script{
                    skipRemainingStages = false
                    helpers.installRequirements()
                    sh """
                    echo "==== install helm ===="
                    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
                    chmod 700 get_helm.sh
                    ./get_helm.sh
                    """
                    sh """
                    echo "==== install kubectl krelay plugin ===="
                    curl -fsSL -O https://github.com/knight42/krelay/releases/download/v0.1.2/kubectl-relay_v0.1.2_linux-amd64.tar.gz
                    tar -xzf kubectl-relay_v0.1.2_linux-amd64.tar.gz kubectl-relay
                    mv kubectl-relay /usr/local/bin/
                    """
                    sh """
                    echo "==== install azure cli ===="
                    rpm --import https://packages.microsoft.com/keys/microsoft.asc
                    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
                    dnf install -y azure-cli
                    """
                    withCredentials([file(credentialsId: 'thuyn-azure-sp', variable: 'azure_sp')]) {
                        CLIENT_ID = sh(returnStdout: true, script: "cat $azure_sp | jq -r '.clientId'").trim()
                        CLIENT_SECRET = sh(returnStdout: true, script: "cat $azure_sp | jq -r '.clientSecret'").trim()
                        TENANT_ID = sh(returnStdout: true, script: "cat $azure_sp | jq -r '.tenantId'").trim()
                        sh "az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET -t $TENANT_ID > /dev/null"
                    }
                    sh """
                    echo "==== oc version ===="
                    oc version
                    echo "==== az version ===="
                    az --version
                    echo "==== install kubelogin ===="
                    az aks install-cli
                    echo "==== register DisableSSHPreview feature ===="
                    az feature register --namespace "Microsoft.ContainerService" --name "DisableSSHPreview"
                    az provider register --namespace "Microsoft.ContainerService"
                    """
                }
            }
        }
        stage('Deploy-Service-Cluster') {
            steps {
                script{
                    try{
                        sh """
                        echo "==== clone aro-hcp ===="
                        git clone -b "${params.GIT_BRANCH}" https://github.com/stolostron/ARO-HCP.git aro-hcp/
                        echo "==== enter dev-infrastructure directory ===="
                        cd aro-hcp/dev-infrastructure
                        echo "==== deploy svc-cluster ===="
                        AKSCONFIG=svc-cluster make cluster && AKSCONFIG=svc-cluster make aks.admin-access && AKSCONFIG=svc-cluster make aks.kubeconfig
                        """
                    }
                    catch (e){
                        echo 'Failed to run Deploy-Service-Cluster - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
        stage('Deploy-Management-Cluster') {
            when {
                expression {
                    !skipRemainingStages
                }
            }
            steps {
                script {
                    try{
                        sh """
                        echo "==== enter dev-infrastructure directory ===="
                        cd aro-hcp/dev-infrastructure
                        echo "==== deploy mgmt-cluster ===="
                        AKSCONFIG=mgmt-cluster make cluster && AKSCONFIG=mgmt-cluster make aks.admin-access && AKSCONFIG=mgmt-cluster make aks.kubeconfig
                        """
                    }
                    catch (e){
                        echo 'Failed to run Deploy-Management-Cluster - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
        stage('Deploy-Maestro-Server') {
            when {
                expression {
                    !skipRemainingStages
                }
            }
            steps {
                script {
                    try{
                        sh """
                        echo "==== ensure svc cluster access ===="
                        ls -l ~/.kube/svc-cluster.kubeconfig
                        oc --kubeconfig ~/.kube/svc-cluster.kubeconfig get ns
                        echo "==== enter maestro directory ===="
                        cd aro-hcp/maestro
                        echo "==== deploy maestro server ===="
                        KUBECONFIG=~/.kube/svc-cluster.kubeconfig AKSCONFIG=svc-cluster make deploy-server
                        """
                    }
                    catch (e){
                        echo 'Failed to run Deploy-Maestro-Server - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
        stage('Deploy-Maestro-Agent') {
            when {
                expression {
                    !skipRemainingStages
                }
            }
            steps {
                script {
                    try{
                        sh """
                        echo "==== ensure mgmt cluster access ===="
                        ls -l ~/.kube/mgmt-cluster.kubeconfig
                        oc --kubeconfig ~/.kube/mgmt-cluster.kubeconfig get ns
                        echo "==== enter maestro directory ===="
                        cd aro-hcp/maestro
                        echo "==== deploy maestro agent ===="
                        KUBECONFIG=~/.kube/mgmt-cluster.kubeconfig AKSCONFIG=mgmt-cluster make deploy-agent
                        """
                    }
                    catch (e){
                        echo 'Failed to run Deploy-Maestro-Agent - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
        stage('Register-Maestro-Consumer') {
            when {
                expression {
                    !skipRemainingStages
                }
            }
            steps {
                script {
                    try{
                        sh """
                        echo "==== ensure svc cluster kubeconfig ===="
                        ls -l ~/.kube/svc-cluster.kubeconfig
                        echo "==== enter maestro directory ===="
                        cd aro-hcp/maestro
                        echo "==== register maestro consumer ===="
                        KUBECONFIG=~/.kube/svc-cluster.kubeconfig AKSCONFIG=svc-cluster make register-agent
                        """
                    }
                    catch (e){
                        echo 'Failed to run Register-Maestro-Consumer - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
        stage('Run e2e Tests') {
            when {
                expression {
                    !skipRemainingStages
                }
            }
            steps {
                script {
                    try{
                        sh """
                        echo "==== ensure svc cluster kubeconfig ===="
                        ls -l ~/.kube/svc-cluster.kubeconfig
                        oc --kubeconfig ~/.kube/svc-cluster.kubeconfig wait --for=condition=available --timeout=120s -n maestro deploy/maestro
                        oc --kubeconfig ~/.kube/svc-cluster.kubeconfig -n maestro get pod
                        echo "==== port-forward maestro service ===="
                        oc relay --kubeconfig ~/.kube/svc-cluster.kubeconfig -n maestro service/maestro 8000:8000 &
                        oc relay --kubeconfig ~/.kube/svc-cluster.kubeconfig -n maestro service/maestro-grpc 8090:8090 &
                        sleep 10
                        echo "==== clone maestro ===="
                        git clone -b "${params.GIT_BRANCH}" https://github.com/openshift-online/maestro.git maestro/
                        echo "==== enter maestro directory ===="
                        cd maestro
                        echo "==== run e2e tests ===="
                        ginkgo -v --label-filter="!(e2e-tests-spec-resync-reconnect||e2e-tests-status-resync-reconnect)" --output-dir=./test/e2e/report --json-report=report.json --junit-report=report.xml ./test/e2e/pkg -- -api-server=http://localhost:8000 -grpc-server=localhost:8090 -server-kubeconfig="/root/.kube/svc-cluster.kubeconfig" -consumer-name=aro-hcp-acmqe-eastus-mgmt-cluster -agent-kubeconfig="/root/.kube/mgmt-cluster.kubeconfig" -agent-namespace=maestro
                        """
                    }
                    catch (e){
                        echo 'Failed to run e2e-tests - ' + e.getMessage()
                        currentBuild.result = 'FAILURE'
                        skipRemainingStages = true
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'maestro/test/e2e/report/', followSymlinks: false, fingerprint: true
        }
    }
}
