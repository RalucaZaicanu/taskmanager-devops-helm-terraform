pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 90, unit: 'MINUTES')
    }

    environment {
        DOCKER_IMAGE = "ralucazaicanu/task-manager"
        IMAGE_TAG = "${BUILD_NUMBER}"

        TF_DIR = "terraform/environments/dev"

        HELM_CHART = "helm/task-manager"
        RELEASE_NAME = "task-manager"
        KUBE_NAMESPACE = "task-manager"

        KUBECONFIG = "${WORKSPACE}/kubeconfig.yaml"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh 'terraform fmt -check -recursive terraform'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform plan -out=tfplan'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }

                archiveArtifacts artifacts: "${TF_DIR}/tfplan.txt", fingerprint: true
            }
        }

        stage('Manual Approval for Terraform Apply') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Review the Terraform plan. Do you want to apply these infrastructure changes?',
                          ok: 'Apply Terraform'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform apply tfplan'
                    }
                }
            }
        }

        stage('Get Kubernetes Kubeconfig') {
            steps {
                script {
                    env.K8S_PUBLIC_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw k8s_control_plane_public_ip",
                        returnStdout: true
                    ).trim()

                    env.K8S_PRIVATE_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw k8s_control_plane_private_ip",
                        returnStdout: true
                    ).trim()
                }

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'aws-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        echo "Waiting for Kubernetes kubeconfig..."

                        for i in $(seq 1 30); do
                            ssh -i "$SSH_KEY" \
                                -o StrictHostKeyChecking=no \
                                "$SSH_USER@$K8S_PUBLIC_IP" \
                                "sudo test -f /etc/rancher/k3s/k3s.yaml" && break

                            echo "Kubernetes is not ready yet. Waiting..."
                            sleep 10
                        done

                        ssh -i "$SSH_KEY" \
                            -o StrictHostKeyChecking=no \
                            "$SSH_USER@$K8S_PUBLIC_IP" \
                            "sudo cat /etc/rancher/k3s/k3s.yaml" > "$KUBECONFIG"

                        sed -i "s/127.0.0.1/$K8S_PRIVATE_IP/g" "$KUBECONFIG"

                        chmod 600 "$KUBECONFIG"

                        kubectl get nodes
                    '''
                }
            }
        }

        stage('Maven Test and Package') {
            steps {
                dir('app') {
                    sh 'mvn clean test package'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $DOCKER_IMAGE:$IMAGE_TAG ./app
                    docker tag $DOCKER_IMAGE:$IMAGE_TAG $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Docker Login and Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        docker push $DOCKER_IMAGE:$IMAGE_TAG
                        docker push $DOCKER_IMAGE:latest
                    '''
                }
            }
        }

        stage('Helm Lint') {
            steps {
                sh 'helm lint $HELM_CHART'
            }
        }

        stage('Helm Deploy') {
            steps {
                sh '''
                    helm upgrade --install $RELEASE_NAME $HELM_CHART \
                        --namespace $KUBE_NAMESPACE \
                        --create-namespace \
                        --set image.repository=$DOCKER_IMAGE \
                        --set image.tag=$IMAGE_TAG \
                        --wait \
                        --timeout 5m
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get nodes
                    kubectl get pods -n $KUBE_NAMESPACE
                    kubectl get svc -n $KUBE_NAMESPACE
                    kubectl get ingress -n $KUBE_NAMESPACE || true
                    helm list -n $KUBE_NAMESPACE
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs above.'
        }

        always {
            sh '''
                docker logout || true
            '''
        }
    }
}