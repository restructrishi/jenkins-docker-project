pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = "rishingm/jenkins-docker-project"
        // Remove the credentials() binding from environment
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
                    // Pass the credential ID as a string directly
                    docker.withRegistry('', 'rishingm') {
                        docker.image("${DOCKER_IMAGE_NAME}").push("latest")
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    echo "Deploying the application..."
                    // Stop and remove old container if exists
                    sh 'docker stop my-web-app || true'
                    sh 'docker rm my-web-app || true'
                    // Run new container
                    sh "docker run -d --name my-web-app -p 3000:3000 ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }
    }
}