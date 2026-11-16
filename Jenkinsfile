pipeline {
    agent { label 'AWS-Ubuntu-Agent' }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        TF_VAR_ami_id = 'ami-09d8c1e69d114dbf7'
        TF_VAR_allowed_cidr = '13.207.182.45/32'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-terraform-user',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        terraform init -input=false
                        terraform fmt -check
                        terraform validate
                        terraform plan -input=false
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'docker build -t "$DOCKER_USER/networkz-web:v1" .'
                }
            }
        }

        stage('Docker Login and Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push "$DOCKER_USER/networkz-web:v1"
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        docker pull "$DOCKER_USER/networkz-web:v1"
                        docker rm -f networkz-web || true
                        docker run -d --name networkz-web -p 8081:80 "$DOCKER_USER/networkz-web:v1"
                        curl -fsS http://localhost:8081
                    '''
                }
            }
        }
    }
}
