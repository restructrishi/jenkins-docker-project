pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = "rishingm/jenkins-docker-project"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "Cloning repository from GitHub..."
                git branch: 'main', url: 'https://github.com/restructrishi/jenkins-docker-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building the Docker image..."
                    docker.build("${DOCKER_IMAGE_NAME}", '.')
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Logging in and pushing the Docker image to Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'rishingm',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh "docker push ${DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    echo "Deploying the application..."
                    sh 'docker stop my-web-app || true'
                    sh 'docker rm my-web-app || true'
                    sh "docker run -d --name my-web-app -p 3000:3000 ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }
    }
}