# Jenkins Pipeline Setup Guide
## Java / Maven + Docker Build & Push — Declarative Pipeline

---

## 📁 Project File Structure

Place these files in the ROOT of your repository:

```
your-project/
├── Jenkinsfile          ← Pipeline definition
├── Dockerfile           ← Docker image build instructions
├── pom.xml              ← Maven project file
└── src/                 ← Java source code
```

---

## ✅ Prerequisites

| Requirement         | Details                                      |
|---------------------|----------------------------------------------|
| Jenkins version     | 2.387+ recommended                           |
| Jenkins plugins     | Pipeline, Docker Pipeline, Git, JUnit        |
| Jenkins agent       | Must have Docker CLI + Docker daemon access  |
| Java on agent       | JDK 17                                       |
| Maven on agent      | Maven 3.9.x                                  |
| Docker Hub account  | hub.docker.com                               |

---

## 🔧 Step 1 — Configure Global Tools in Jenkins

1. Go to: **Manage Jenkins → Global Tool Configuration**
2. Under **JDK**, click **Add JDK**:
   - Name: `JDK-17`
   - Install automatically: ✅ (or set JAVA_HOME manually)
3. Under **Maven**, click **Add Maven**:
   - Name: `Maven-3.9`
   - Install automatically: ✅

> ⚠️ The names `JDK-17` and `Maven-3.9` must **exactly match** what's in the Jenkinsfile `tools {}` block.

---

## 🔑 Step 2 — Add Docker Hub Credentials

1. Go to: **Manage Jenkins → Credentials → (global) → Add Credentials**
2. Fill in:
   - **Kind**: Username with password
   - **Username**: your Docker Hub username
   - **Password**: your Docker Hub password or access token
   - **ID**: `docker-hub-credentials`  ← must match Jenkinsfile exactly
   - **Description**: Docker Hub Login

---

## ✏️ Step 3 — Update the Jenkinsfile

Open `Jenkinsfile` and update these two lines:

```groovy
DOCKER_IMAGE_NAME = 'your-dockerhub-username/your-app-name'
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                   Replace with your actual Docker Hub repo
```

Example:
```groovy
DOCKER_IMAGE_NAME = 'johnsmith/my-spring-app'
```

---

## 🏗️ Step 4 — Create the Jenkins Pipeline Job

1. Jenkins Dashboard → **New Item**
2. Enter a name (e.g., `java-docker-pipeline`)
3. Select **Pipeline** → click **OK**
4. Under **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/your-org/your-repo.git`
   - Credentials: add your GitHub credentials if private repo
   - Branch: `*/main` (or your branch name)
   - Script Path: `Jenkinsfile`
5. Click **Save**

---

## ▶️ Step 5 — Run the Pipeline

1. Click **Build Now** on the pipeline job page
2. Click the build number → **Console Output** to watch live logs
3. Pipeline stages will run in order:

```
[Checkout] → [Build] → [Test] → [Docker Build] → [Docker Push] → [Cleanup]
```

---

## 🐳 Step 6 — Verify Docker Image on Docker Hub

After a successful run, your image will be available at:

```
https://hub.docker.com/r/your-dockerhub-username/your-app-name
```

Pull and run it locally to verify:

```bash
docker pull your-dockerhub-username/your-app-name:latest
docker run -p 8080:8080 your-dockerhub-username/your-app-name:latest
```

---

## 🔁 Pipeline Stages Explained

| Stage         | What It Does                                              |
|---------------|-----------------------------------------------------------|
| Checkout      | Clones source code from Git                              |
| Build         | Runs `mvn clean package -DskipTests`, archives the JAR   |
| Test          | Runs `mvn test`, publishes JUnit XML reports              |
| Docker Build  | Builds image with versioned + latest tag                 |
| Docker Push   | Logs in to Docker Hub and pushes both tags               |
| Cleanup       | Removes local images, wipes Jenkins workspace            |

---

## 🛠️ Common Errors & Fixes

| Error                                  | Fix                                                        |
|----------------------------------------|------------------------------------------------------------|
| `docker: command not found`            | Install Docker on Jenkins agent; add jenkins user to docker group |
| `permission denied /var/run/docker.sock` | Run: `sudo usermod -aG docker jenkins` then restart Jenkins |
| `Invalid credentials ID`               | Check credential ID matches `docker-hub-credentials` exactly |
| `Maven goal not found`                 | Verify tool name `Maven-3.9` matches Global Tool Configuration |
| `No such file: target/*.jar`           | Ensure `mvn package` succeeded in the Build stage          |

---

## 💡 Optional Enhancements

- **Slack notifications**: Add `slackSend` in the `post {}` block
- **SonarQube scan**: Uncomment the SonarQube stage in Jenkinsfile
- **Deploy stage**: Add `docker run` or `kubectl apply` after the push
- **Webhook trigger**: Enable GitHub webhook to auto-trigger builds on push
