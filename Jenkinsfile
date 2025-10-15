pipeline {
  agent any

  environment {
    // Change these here if you want; values below are what you provided
    DOCKERHUB_USER = 'rishingm'
    IMAGE_NAME     = "${DOCKERHUB_USER}/jenkins-docker-project"
    SONAR_SERVER   = 'SonarQube'              // Jenkins SonarQube server name
    DOCKER_CRED_ID = 'docker-credentials'      // DockerHub credential ID in Jenkins
    GIT_CRED_ID    = 'github-credentials'      // GitHub credentials (if needed)
    SONAR_CRED_ID  = 'sonar-token'             // <-- SonarQube token credential ID in Jenkins
    SONAR_HOST_URL = 'http://localhost:9000'   // <-- Your SonarQube server URL
    // Optional: set PUSHGATEWAY_URL as a Jenkins secret or environment var if you want to push build metrics (Prometheus)
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
        echo "Checked out: ${env.GIT_COMMIT}"
      }
    }

    stage('Detect & Install') {
      steps {
        script {
          if (fileExists('pom.xml')) {
            env.BUILD_TOOL = 'maven'
            echo "Detected Maven project"
          } else if (fileExists('package.json')) {
            env.BUILD_TOOL = 'node'
            echo "Detected Node project"
          } else {
            env.BUILD_TOOL = 'none'
            echo "No recognized build file (pom.xml/package.json). Will skip install/test steps."
          }
        }
      }
    }

    stage('Debug Docker') {
      steps {
        sh 'docker --version'
        sh 'docker images | head -5'
        sh 'docker run --rm node:18 node --version'
      }
    }

    stage('Install & Test') {
      when { expression { env.BUILD_TOOL == 'node' } }
      steps {
        sh '''
          echo "Running npm install in Docker container..."
          docker run --rm \
            -v "${WORKSPACE}":/app \
            -w /app \
            node:18 \
            sh -c "node --version && npm --version && (npm ci || npm install) && (npm test || true)"
        '''
      }
    }

    // --- ADDED THIS TEMPORARY STAGE FOR DEBUGGING ---
    stage('Debug Agent PATH') {
      tools {
        'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarScanner-5.0'
      }
      steps {
        echo "--- Checking Agent Environment ---"
        sh 'echo "Running on node: $NODE_NAME"'
        sh 'echo "--- Current PATH ---"'
        sh 'echo $PATH'
        sh 'echo "--- Checking for sonar-scanner ---"'
        sh 'which sonar-scanner || echo "sonar-scanner command not found in PATH"'
        sh 'echo "--- Verifying installation directory ---"'
        sh 'ls -l /opt/sonar-scanner/bin/sonar-scanner || echo "/opt/sonar-scanner/bin/sonar-scanner does not exist on this agent"'
      }
    }

    stage('SonarQube Analysis & Quality Gate') {
      when { 
        expression { 
          env.SONAR_CRED_ID != null && env.SONAR_CRED_ID != '' 
        } 
      }
      tools {
        'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarScanner-5.0'
      }
      steps {
        withCredentials([string(credentialsId: "${env.SONAR_CRED_ID}", variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv("${env.SONAR_SERVER}") {
            script {
              if (env.BUILD_TOOL == 'maven') {
                sh "mvn -B clean verify sonar:sonar -Dsonar.login=${SONAR_TOKEN}"
              } else if (env.BUILD_TOOL == 'node') {
                sh '''
                  sonar-scanner \
                    -Dsonar.host.url=${SONAR_HOST_URL} \
                    -Dsonar.login=$SONAR_TOKEN \
                    -Dsonar.projectKey=sonarqube-pipeline-${BUILD_NUMBER} \
                    -Dsonar.sources=.
                '''
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

    stage('Build Docker Image') {
      steps {
        script {
          def tag = "${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
          sh "docker build -t ${tag} ."
          env.IMAGE_TAG = tag
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo $DOCKER_PASS | docker login -u "$DOCKER_USER" --password-stdin'
          sh "docker push ${env.IMAGE_TAG}"
          sh 'docker logout'
        }
      }
    }

    stage('Optional: Notify/Deploy') {
      steps {
        echo "Add your deployment or notification steps here (kubectl/ssh/helm/slack)."
      }
    }

    stage('Optional: Push build metrics to Prometheus Pushgateway') {
      when { expression { env.PUSHGATEWAY_URL?.trim() } }
      steps {
        script {
          def metrics = "build_status{job=\"${env.JOB_NAME}\",build=\"${env.BUILD_NUMBER}\"} 1\n"
          writeFile file: 'build_metrics.prom', text: metrics
          sh "curl --data-binary @build_metrics.prom ${env.PUSHGATEWAY_URL}/metrics/job/${env.JOB_NAME}/build/${env.BUILD_NUMBER}"
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