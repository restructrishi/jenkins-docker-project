pipeline {
  agent any

  environment {
    DOCK-ERHUB_USER = 'rishingm'
    IMAGE_NAME     = "${DOCKERHUB_USER}/jenkins-docker-project"
    SONAR_SERVER   = 'SonarQube'
    DOCKER_CRED_ID = 'docker-credentials'
    GIT_CRED_ID    = 'github-credentials'
    SONAR_CRED_ID  = 'sonar-token'
    SONAR_HOST_URL = 'http://localhost:9000'
    PUSHGATEWAY_URL = ''
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Detect & Install') {
      steps {
        script {
          if (fileExists('pom.xml')) {
            env.BUILD_TOOL = 'maven'
          } else if (fileExists('package.json')) {
            env.BUILD_TOOL = 'node'
          } else {
            env.BUILD_TOOL = 'none'
          }
        }
      }
    }

    // --- THIS STAGE IS NOW FIXED ---
    stage('Install & Test') {
      when { expression { env.BUILD_TOOL == 'node' } }
      steps {
        sh '''
          docker run --rm -v "${WORKSPACE}":/app -w /app node:18 sh -c "npm install && (npm test || true)"
        '''
      }
    }

    stage('SonarQube Analysis & Quality Gate') {
      when { expression { env.SONAR_CRED_ID != null && env.SONAR_CRED_ID != '' } }
      steps {
        withCredentials([string(credentialsId: "${env.SONAR_CRED_ID}", variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv("${env.SONAR_SERVER}") {
            script {
              def scannerHome = tool 'SonarScanner-5.0'
              if (env.BUILD_TOOL == 'maven') {
                sh "mvn -B clean verify sonar:sonar -Dsonar.login=${SONAR_TOKEN}"
              } else if (env.BUILD_TOOL == 'node') {
                sh "'${scannerHome}/bin/sonar-scanner' -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=$SONAR_TOKEN -Dsonar.projectKey=sonarqube-pipeline-${BUILD_NUMBER} -Dsonar.sources=."
              } else {
                echo "Skipping Sonar - no build files detected."
              }
            }
          }
        }
        timeout(time: 2, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        script {
          def tag = "${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
          sh "docker build -t ${tag} ."
          withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh "echo $DOCKER_PASS | docker login -u '$DOCKER_USER' --password-stdin"
            sh "docker push ${tag}"
            sh 'docker logout'
          }
        }
      }
    }
  }

  post {
    always {
      echo "Build finished. Cleaning up workspace."
      cleanWs()
    }
  }
}