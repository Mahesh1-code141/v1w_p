pipeline {
    agent any

    environment {
        // ── Docker Hub credentials (saved in Jenkins as 'Dockerhub') ──────────
        DOCKER_HUB_CREDENTIALS = credentials('Dockerhub')
        DOCKER_HUB_USERNAME    = 'mahesh2452'

        // ── Image & Container names ───────────────────────────────────────────
        DOCKER_IMAGE_NAME      = 'mahesh2452/v1w-app'
        CONTAINER_NAME         = 'v1w-container'
        DOCKER_IMAGE_TAG       = "${env.BUILD_NUMBER}"
        DOCKER_IMAGE_LATEST    = "${DOCKER_IMAGE_NAME}:latest"
        DOCKER_IMAGE_VERSIONED = "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"

        // ── Maven ─────────────────────────────────────────────────────────────
        MAVEN_OPTS             = '-Xmx1024m'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        // ── 1. CHECKOUT ────────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥 Cloning from GitHub...'
                git branch: 'main',
                    url: 'https://github.com/Mahesh1-code141/v1w_p.git'
            }
        }

        // ── 2. VERIFY TOOLS ────────────────────────────────────────────────────
        stage('Verify Tools') {
            steps {
                echo '🔍 Checking installed tool versions...'
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker --version'
                sh 'ls -la'           // Show repo files for confirmation
            }
        }

        // ── 3. BUILD WITH MAVEN ────────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '🔨 Building project with Maven...'
                sh 'mvn clean package -DskipTests'
            }
            post {
                success {
                    echo '✅ Maven build succeeded.'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
                failure {
                    echo '❌ Maven build failed. Check logs above.'
                }
            }
        }

        // ── 4. UNIT TESTS ──────────────────────────────────────────────────────
        stage('Test') {
            steps {
                echo '🧪 Running unit tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        // ── 5. DOCKER BUILD ────────────────────────────────────────────────────
        stage('Docker Build') {
            steps {
                echo "🐳 Building Docker image: ${DOCKER_IMAGE_VERSIONED}"
                sh """
                    docker build \
                        -t ${DOCKER_IMAGE_VERSIONED} \
                        -t ${DOCKER_IMAGE_LATEST} \
                        .
                """
            }
        }

        // ── 6. DOCKER PUSH ─────────────────────────────────────────────────────
        stage('Docker Push') {
            steps {
                echo "🚀 Pushing image to Docker Hub as ${DOCKER_HUB_USERNAME}..."
                withCredentials([usernamePassword(
                    credentialsId: 'Dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ''' + "${DOCKER_IMAGE_VERSIONED}" + '''
                        docker push ''' + "${DOCKER_IMAGE_LATEST}" + '''
                    '''
                }
            }
            post {
                always {
                    sh 'docker logout'
                }
            }
        }

        // ── 7. RUN CONTAINER ───────────────────────────────────────────────────
        stage('Run Container') {
            steps {
                echo "🟢 Starting container: ${CONTAINER_NAME}"
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm   ${CONTAINER_NAME} || true

                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p 8080:8080 \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE_LATEST}
                """
            }
        }

        // ── 8. CLEANUP LOCAL IMAGES ────────────────────────────────────────────
        stage('Cleanup') {
            steps {
                echo '🧹 Removing dangling Docker images...'
                sh """
                    docker rmi ${DOCKER_IMAGE_VERSIONED} || true
                    docker image prune -f               || true
                """
            }
        }
    }

    // ── GLOBAL POST ACTIONS ────────────────────────────────────────────────────
    post {
        success {
            echo """
            ╔══════════════════════════════════════════════════════╗
            ║  ✅ Pipeline completed successfully!                  ║
            ║  Image    : ${DOCKER_IMAGE_VERSIONED}
            ║  Container: ${CONTAINER_NAME}
            ║  App URL  : http://<your-server-ip>:8080
            ╚══════════════════════════════════════════════════════╝
            """
        }
        failure {
            echo '❌ Pipeline FAILED. Review the stage logs above.'
        }
        always {
            cleanWs()
        }
    }
}

