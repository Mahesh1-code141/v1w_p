pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('Dockerhub')
        DOCKER_HUB_USERNAME    = 'mahesh2452'
        DOCKER_IMAGE_NAME      = 'mahesh2452/v1w-app'
        CONTAINER_NAME         = 'v1w-container'
        DOCKER_IMAGE_TAG       = "${env.BUILD_NUMBER}"
        DOCKER_IMAGE_LATEST    = "${DOCKER_IMAGE_NAME}:latest"
        DOCKER_IMAGE_VERSIONED = "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
        MAVEN_OPTS             = '-Xmx1024m'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                echo '📥 Cloning from GitHub...'
                git branch: 'main',
                    url: 'https://github.com/Mahesh1-code141/v1w_p.git'
            }
        }

        stage('Verify Tools') {
            steps {
                echo '🔍 Checking installed tool versions...'
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker --version'
                sh 'ls -la'
            }
        }

        // ── 3. FIX FILENAME MISMATCH ───────────────────────────────────────────
        stage('Fix Source Files') {
            steps {
                echo '🔧 Checking and fixing Java filename mismatches...'
                sh '''
                    echo "📂 Scanning Java source files..."
                    find src/main/java -name "*.java" | while read FILE; do
                        # Extract the public class name declared inside the file
                        CLASS_NAME=$(grep -m1 "^public class " "$FILE" | awk '{print $3}')
                        if [ -z "$CLASS_NAME" ]; then
                            echo "⚠️  No public class found in $FILE — skipping."
                            continue
                        fi

                        EXPECTED_NAME="${CLASS_NAME}.java"
                        ACTUAL_NAME=$(basename "$FILE")
                        DIR=$(dirname "$FILE")

                        if [ "$ACTUAL_NAME" != "$EXPECTED_NAME" ]; then
                            echo "🔄 Mismatch detected!"
                            echo "   File    : $ACTUAL_NAME"
                            echo "   Expected: $EXPECTED_NAME"
                            mv "$FILE" "$DIR/$EXPECTED_NAME"
                            echo "✅ Renamed: $ACTUAL_NAME → $EXPECTED_NAME"
                        else
                            echo "✅ OK: $ACTUAL_NAME matches class name."
                        fi
                    done
                '''
            }
            post {
                failure {
                    echo '❌ Failed to fix source file names. Check the logs above.'
                }
            }
        }

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
