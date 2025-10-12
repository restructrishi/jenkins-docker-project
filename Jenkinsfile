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
                        bat 'docker login -u %DOCKER_USER% -p %DOCKER_PASS%'
                        bat "docker push ${DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    echo "Deploying the application..."
                    bat 'docker stop my-web-app || exit 0'
                    bat 'docker rm my-web-app || exit 0'
                    bat "docker run -d --name my-web-app -p 3000:3000 ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }
    }
}