pipeline {
  agent {
    docker {
      image 'docker:27-cli'
      args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  environment {
    DOCKER_BUILDKIT = "1"
    DOCKER_REGISTRY = 'your-registry.com'
    IMAGE_NAME = 'food-delivery'
    SONAR_HOST = 'http://sonarqube:9000'
    // Helper to get the Jenkins container ID dynamically
    JENKINS_CONTAINER = sh(script: 'docker ps -qf "name=jenkins"', returnStdout: true).trim()
    WORKSPACE_PATH = "/var/jenkins_home/workspace/Food-Delivery-Pipeline" 
  }

  tools {
    nodejs 'NodeJS-18'
  }

  stages {
    stage('🔍 Checkout') {
      steps {
        checkout scm
        script {
          env.GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()
        }
      }
    }

        stage('📦 Install Dependencies') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('backend') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        stage('🔐 SAST - SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=food-delivery \
                            -Dsonar.sources=backend/,frontend/src/ \
                            -Dsonar.exclusions=**/node_modules/**,**/dist/** \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    '''
                }
            }
        }

        stage('🔍 Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('🛡️ Dependency Check') {
            parallel {
                stage('Backend Audit') {
                    steps {
                        dir('backend') {
                            sh 'npm audit --audit-level=high --json > npm-audit-backend.json || true'
                            archiveArtifacts artifacts: 'npm-audit-backend.json'
                        }
                    }
                }
                stage('Frontend Audit') {
                    steps {
                        dir('frontend') {
                            sh 'npm audit --audit-level=high --json > npm-audit-frontend.json || true'
                            archiveArtifacts artifacts: 'npm-audit-frontend.json'
                        }
                    }
                }
                stage('OWASP Check') {
                    steps {
                        dependencyCheck additionalArguments: '''
                            --scan .
                            --format HTML
                            --format JSON
                            --prettyPrint
                        ''', odcInstallation: 'OWASP-DC'
                        dependencyCheckPublisher pattern: 'dependency-check-report.json'
                    }
                }
            }
        }

        stage('🧪 Unit Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            sh 'npm test -- --coverage --coverageReporters=lcov'
                        }
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'backend/coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Backend Coverage'
                            ])
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm test -- --coverage --watchAll=false'
                        }
                    }
                }
            }
        }

        stage('🐳 Build Docker Images') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${GIT_COMMIT_SHORT}", "./backend")
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${GIT_COMMIT_SHORT}", "./frontend")
                }
            }
        }

        stage('🔒 Container Security Scan') {
            steps {
                sh '''
                    # Install Trivy
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

                    # Scan Backend Image
                    trivy image --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-backend.json \
                        ${DOCKER_REGISTRY}/${IMAGE_NAME}-backend:${GIT_COMMIT_SHORT}

                    # Scan Frontend Image
                    trivy image --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-frontend.json \
                        ${DOCKER_REGISTRY}/${IMAGE_NAME}-frontend:${GIT_COMMIT_SHORT}
                '''
                archiveArtifacts artifacts: 'trivy-*.json'
            }
        }

        stage('🚀 Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh '''
                    docker-compose -f docker-compose.staging.yml down
                    docker-compose -f docker-compose.staging.yml up -d
                '''
            }
        }

        stage('🎯 DAST - OWASP ZAP') {
            when {
                branch 'develop'
            }
            steps {
                sh '''
                    docker run --rm -v $(pwd):/zap/wrk:rw \
                        -t owasp/zap2docker-stable zap-baseline.py \
                        -t http://staging-url:80 \
                        -r zap-report.html \
                        -J zap-report.json || true
                '''
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'zap-report.html',
                    reportName: 'OWASP ZAP Report'
                ])
            }
        }

        stage('🏭 Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                sh '''
                    docker-compose -f docker-compose.prod.yml down
                    docker-compose -f docker-compose.prod.yml up -d
                '''
            }
        }
    }

    post {
        always {
            node('') {
                cleanWs()
            }
        }
        success {
            echo '✅ Pipeline SUCCESS!'
            // Uncomment when Slack is configured with credentials
            // slackSend channel: '#devops',
            //     color: 'good',
            //     message: "✅ Pipeline SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            echo '❌ Pipeline FAILED!'
            // Uncomment when Slack is configured with credentials
            // slackSend channel: '#devops',
            //     color: 'danger',
            //     message: "❌ Pipeline FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}
