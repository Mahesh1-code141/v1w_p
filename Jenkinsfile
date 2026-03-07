pipeline {
    agent any

    environment {
        // ── Docker Hub credentials (set in Jenkins > Manage Credentials) ──
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE_NAME      = 'your-dockerhub-username/your-app-name'
        DOCKER_IMAGE_TAG       = "${env.BUILD_NUMBER}"          // e.g. :42
        DOCKER_IMAGE_LATEST    = "${DOCKER_IMAGE_NAME}:latest"
        DOCKER_IMAGE_VERSIONED = "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"

        // ── Maven settings ──
        MAVEN_OPTS = '-Xmx1024m'
    }

    tools {
        maven 'Maven-3.9'       // Name configured in Jenkins > Global Tool Configuration
        jdk   'JDK-17'          // Name configured in Jenkins > Global Tool Configuration
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        // ── 1. CHECKOUT ────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Cloning source code...'
                checkout scm
                // Or use an explicit Git URL:
                // git branch: 'main',
                //     credentialsId: 'github-credentials',
                //     url: 'https://github.com/your-org/your-repo.git'
            }
        }

        // ── 2. BUILD WITH MAVEN ────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '🔨 Building with Maven...'
                sh 'mvn clean package -DskipTests'
            }
            post {
                success {
                    echo '✅ Build succeeded.'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
                failure {
                    echo '❌ Build failed.'
                }
            }
        }

        // ── 3. UNIT TESTS ──────────────────────────────────────────────────
        stage('Test') {
            steps {
                echo '🧪 Running unit tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        // ── 4. CODE QUALITY (optional – comment out if SonarQube not set up) ──
        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv('SonarQube') {
        //             sh 'mvn sonar:sonar'
        //         }
        //     }
        // }

        // ── 5. DOCKER BUILD ────────────────────────────────────────────────
        stage('Docker Build') {
            steps {
                echo "🐳 Building Docker image: ${DOCKER_IMAGE_VERSIONED}"
                sh """
                    docker build \
                        --build-arg JAR_FILE=target/*.jar \
                        -t ${DOCKER_IMAGE_VERSIONED} \
                        -t ${DOCKER_IMAGE_LATEST} \
                        .
                """
            }
        }

        // ── 6. DOCKER PUSH ─────────────────────────────────────────────────
        stage('Docker Push') {
            steps {
                echo "🚀 Pushing image to Docker Hub..."
                sh """
                    echo "${DOCKER_HUB_CREDENTIALS_PSW}" | \
                    docker login -u "${DOCKER_HUB_CREDENTIALS_USR}" --password-stdin

                    docker push ${DOCKER_IMAGE_VERSIONED}
                    docker push ${DOCKER_IMAGE_LATEST}
                """
            }
            post {
                always {
                    sh 'docker logout'
                }
            }
        }

        // ── 7. CLEANUP LOCAL IMAGES ────────────────────────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Removing local Docker images...'
                sh """
                    docker rmi ${DOCKER_IMAGE_VERSIONED} || true
                    docker rmi ${DOCKER_IMAGE_LATEST}    || true
                """
            }
        }
    }

    // ── GLOBAL POST ACTIONS ────────────────────────────────────────────────
    post {
        success {
            echo """
            ╔══════════════════════════════════════╗
            ║  ✅ Pipeline completed successfully!  ║
            ║  Image: ${DOCKER_IMAGE_VERSIONED}
            ╚══════════════════════════════════════╝
            """
        }
        failure {
            echo '❌ Pipeline FAILED. Check the logs above.'
            // Add email/Slack notification here if needed
        }
        always {
            cleanWs()   // Wipe workspace after every run
        }
    }
}
