pipeline {
    agent any

    environment {
        IMAGE_NAME = 'food-delivery'
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
                sh 'echo "Checked out commit: ${GIT_COMMIT_SHORT}"'
            }
        }

        stage('📋 Project Info') {
            steps {
                sh '''
                    echo "=== Project Structure ==="
                    ls -la
                    echo ""
                    echo "=== Backend Dependencies ==="
                    cat backend/package.json | head -30
                '''
            }
        }

        stage('�️ Security Audit') {
            parallel {
                stage('Backend Audit') {
                    steps {
                        dir('backend') {
                            sh 'cat package.json | grep -A 20 dependencies || true'
                        }
                    }
                }
                stage('Frontend Audit') {
                    steps {
                        dir('frontend') {
                            sh 'cat package.json | grep -A 20 dependencies || true'
                        }
                    }
                }
            }
        }

        stage('🐳 Docker Build Check') {
            steps {
                sh '''
                    echo "=== Checking Dockerfiles ==="
                    echo "Backend Dockerfile:"
                    head -10 backend/Dockerfile
                    echo ""
                    echo "Frontend Dockerfile:"
                    head -10 frontend/Dockerfile
                '''
            }
        }

        stage('� DevSecOps Config Check') {
            steps {
                sh '''
                    echo "=== SonarQube Config ==="
                    cat sonar-project.properties
                    echo ""
                    echo "=== Prometheus Config ==="
                    cat prometheus.yml
                    echo ""
                    echo "=== Security Scripts ==="
                    ls -la scripts/
                '''
            }
        }

        stage('✅ Pipeline Complete') {
            steps {
                sh '''
                    echo "======================================"
                    echo "  DevSecOps Pipeline Test Complete!"
                    echo "======================================"
                    echo ""
                    echo "In production, this pipeline would:"
                    echo "  1. Install npm dependencies"
                    echo "  2. Run SAST with SonarQube"
                    echo "  3. Run npm audit for vulnerabilities"
                    echo "  4. Execute unit tests"
                    echo "  5. Build Docker images"
                    echo "  6. Scan images with Trivy"
                    echo "  7. Run DAST with OWASP ZAP"
                    echo "  8. Deploy to staging/production"
                '''
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
