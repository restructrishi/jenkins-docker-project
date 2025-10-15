pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'rishingm'
    IMAGE_NAME     = "${DOCKERHUB_USER}/jenkins-docker-project"
    SONAR_SERVER   = 'SonarQube'
    DOCKER_CRED_ID = 'docker-credentials'
    GIT_CRED_ID    = 'github-credentials'
    SONAR_CRED_ID  = 'sonar-token'
    SONAR_HOST_URL = 'http://host.docker.internal:9000'   // ✅ Changed: ensure host-docker-internal is used
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

    stage('SonarQube Analysis') {
      when { expression { env.SONAR_CRED_ID?.trim() } }
      steps {
        withCredentials([string(credentialsId: "${env.SONAR_CRED_ID}", variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv("${env.SONAR_SERVER}") {
            script {
              if (env.BUILD_TOOL == 'maven') {
                sh "mvn -B clean verify sonar:sonar -Dsonar.login=${SONAR_TOKEN}"
              } else if (env.BUILD_TOOL == 'node') {
                // ✅ Secure + Corrected Docker Sonar Scanner command
                sh '''
                  docker run --rm \
                    --add-host=host.docker.internal:host-gateway \
                    -v "${WORKSPACE}":/usr/src \
                    -w /usr/src \
                    -e SONAR_TOKEN=$SONAR_TOKEN \
                    sonarsource/sonar-scanner-cli \
                    -Dsonar.host.url=http://host.docker.internal:9000 \
                    -Dsonar.projectKey=${JOB_NAME}-${BUILD_NUMBER} \
                    -Dsonar.sources=.
                '''
              } else {
                echo "Skipping Sonar - no build files detected."
              }
            }
          }
        }
      }
    }

    stage('Wait for Sonar Quality Gate') {
      steps {
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
    success {
      echo "✅ Build succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
    unstable {
      echo "⚠️ Build unstable: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
    failure {
      echo "❌ Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
    always {
      archiveArtifacts artifacts: '**/target/*.jar, **/*.log', allowEmptyArchive: true
      cleanWs()
    }
  }
}
