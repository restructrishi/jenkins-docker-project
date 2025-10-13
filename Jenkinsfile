pipeline {
    agent any

    tools {
        maven 'Maven'
    }

    environment {
        SONARQUBE_SERVER = 'SonarQubeServer' 
        DOCKERHUB_USERNAME = 'your-dockerhub-username' //
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/my-java-app"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/restructrishi/jenkins-docker-project.git', branch: 'main'
            }
        }

        stage('Code Analysis') {
            steps {
                withSonarQubeEnv(SONARQUBE_SERVER) {
                    sh 'mvn clean verify sonar:sonar'
                }
            }
        }
        
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                sh "docker tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ${IMAGE_NAME}:latest"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub-credentials-id', variable: 'DOCKERHUB_PASS')]) {
                    sh "echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }
    }
    
    post {
    always {
        // The "|| true" ensures this step doesn't fail if the image doesn't exist
        sh "docker rmi ${IMAGE_NAME}:${env.BUILD_NUMBER} || true"
        sh "docker rmi ${IMAGE_NAME}:latest || true"
        cleanWs()
    }
        success {
            // This runs only if the build is successful.
            script {
                slackSend(
                    channel: '#build-alerts', // Or your channel name
                    color: 'good', // Green color
                    message: "SUCCESS: Job '${env.JOB_NAME}' build #${env.BUILD_NUMBER} completed successfully. Details: ${env.BUILD_URL}",
                    credentialId: 'slack-webhook-url' // The ID of your credential
                )
            }
        }
        failure {
            // This runs only if the build fails.
            script {
                slackSend(
                    channel: '#build-alerts',
                    color: 'danger', // Red color
                    message: "FAILURE: Job '${env.JOB_NAME}' build #${env.BUILD_NUMBER} failed. Check console output: ${env.BUILD_URL}",
                    credentialId: 'slack-webhook-url'
                )
            }
        }
    }
}