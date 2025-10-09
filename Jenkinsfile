pipeline {
    agent any // This pipeline can run on any available Jenkins agent

    environment {
        // Define a variable for your Docker Hub username
        // We will configure credentials in Jenkins to keep them secret
        DOCKERHUB_CREDENTIALS = credentials('rishingm') 
        DOCKER_IMAGE_NAME = "rishingm/jenkins-docker-project"
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Get the latest code from the 'main' branch of your GitHub repository
                git branch: 'main', url: '[https://github.com/restructrishi/jenkins-docker-project.git](https://github.com/restructrishi/jenkins-docker-project.git)'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image using the Dockerfile in our code
                    echo "Building the Docker image..."
                    docker.build(DOCKER_IMAGE_NAME, '.')
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Log in to Docker Hub using the stored credentials and push the image
                    echo "Pushing the Docker image to Docker Hub..."
                    docker.withRegistry('[https://registry.hub.docker.com](https://registry.hub.docker.com)', DOCKERHUB_CREDENTIALS) {
                        docker.image(DOCKER_IMAGE_NAME).push("latest")
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    echo "Deploying the application..."
                    // Stop and remove any old container with the same name to avoid conflicts
                    sh 'docker stop my-web-app || true'
                    sh 'docker rm my-web-app || true'
                    
                    // Run a new container from the latest image we just pushed
                    sh "docker run -d --name my-web-app -p 3000:3000 ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }
    }
}
