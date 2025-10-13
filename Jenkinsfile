pipeline {
    agent any
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t rishingm/jenkins-docker-project .'
            }
        }
        stage('Run Tests') {
            steps {
                sh 'docker run --rm rishingm/jenkins-docker-project npm test'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push rishingm/jenkins-docker-project:latest
                    '''
                }
            }
        }
    }
}