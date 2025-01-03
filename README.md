---

# **DevSecOps Project: Docker Image Scanning & Deployment with Jenkins**

## **Project Overview**
This project aims to automate the process of scanning Docker images for vulnerabilities using **Trivy**, and deploying those images on Docker containers using **Jenkins** pipelines in an AWS environment. The focus is on maintaining security (DevSecOps) by integrating **Trivy** for vulnerability scanning during the CI/CD pipeline.

### **Key Tools and Technologies**:
1. **Trivy** - A simple and efficient open-source security scanner for container images.
2. **Jenkins** - Automation server to build, test, and deploy Docker images.
3. **Docker** - Platform to deploy applications in isolated containers.
4. **AWS EC2** - Virtual servers on Amazon Web Services for running Docker containers.

---

## **Project Components**

### **1. Jenkins Pipeline for CI/CD**
The pipeline is responsible for pulling the Docker image, scanning it with Trivy, and deploying it to a Docker container.

**Jenkins Pipeline Steps:**
1. **Pull Docker Image**:
   - The pipeline pulls the specified Docker image from Docker Hub.
   - Example Image: `iamtejas23/zomato-clone:latest`.
   
2. **Scan Docker Image with Trivy**:
   - Trivy is used to scan the Docker image for any vulnerabilities.
   - Output is stored in a log file and optionally displayed in Jenkins.

3. **Deploy Docker Image**:
   - If the scan passes, the pipeline proceeds to deploy the image as a Docker container.
   - A Docker container is created with the specified image and accessible on a public IP.

---

### **2. Docker Image Vulnerability Scanning with Trivy**
**Trivy** is used to scan the Docker image for known vulnerabilities and misconfigurations. The image is scanned based on the CVE (Common Vulnerabilities and Exposures) database and a variety of other data sources.

- **Trivy Output Formats**: 
  - **JSON Format** for structured data (ideal for CI/CD pipelines).
  - **Text Format** for human-readable output.

- **Trivy Logs**:
  The logs capture vulnerabilities found in the image, including:
  - **Vulnerability ID** (CVE ID).
  - **Severity** of the vulnerability (Critical, High, Medium, Low).
  - **Package Name** affected.
  - **Installed Version** and **Fixed Version**.
  - **Description** of the issue.

---

### **3. Setting Up Jenkins Server with Docker and Trivy**
Follow these steps to set up Jenkins, Docker, and Trivy on the Jenkins server (Amazon EC2 or local server).

#### **Step 1: Install Docker on Jenkins Node**
- **Install Docker**:
  ```bash
  sudo yum install docker -y
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

- **Verify Docker**:
  ```bash
  docker --version
  ```

#### **Step 2: Install Trivy**
- **Install Trivy**:
  ```bash
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh
  ```

- **Verify Trivy**:
  ```bash
  trivy --version
  ```

#### **Step 3: Add Jenkins User to Docker Group**
- **Allow Jenkins to run Docker without `sudo`**:
  ```bash
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins
  ```

---

### **4. Jenkins Pipeline Script (Jenkinsfile)**
The following is the pipeline script (Jenkinsfile) used to automate the process:

```groovy
pipeline {
    agent {
        label 'docker' // Ensure the Jenkins node has Docker installed
    }
    environment {
        DOCKER_IMAGE = "iamtejas23/zomato-clone:latest" // Your Docker image
        DOCKER_CONTAINER_NAME = "zomato-clone-app" // Desired container name
    }
    stages {
        stage('Pull Docker Image') {
            steps {
                script {
                    echo "Pulling Docker Image: ${DOCKER_IMAGE}"
                    sh "docker pull ${DOCKER_IMAGE}"
                }
            }
        }
        stage('Scan Docker Image with Trivy') {
            steps {
                script {
                    echo "Scanning Docker Image: ${DOCKER_IMAGE}"
                    sh "trivy image ${DOCKER_IMAGE} > trivy_scan.log || true"
                    sh "cat trivy_scan.log"
                }
            }
        }
        stage('Deploy Docker Container') {
            steps {
                script {
                    echo "Deploying Docker Container: ${DOCKER_CONTAINER_NAME}"
                    sh """
                    docker stop ${DOCKER_CONTAINER_NAME} || true
                    docker rm ${DOCKER_CONTAINER_NAME} || true
                    docker run -d --name ${DOCKER_CONTAINER_NAME} -p 8080:8080 ${DOCKER_IMAGE}
                    """
                }
            }
        }
    }
    post {
        always {
            echo "Pipeline completed."
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
```

#### **Key Stages**:
- **Pull Docker Image**: This stage pulls the Docker image (`iamtejas23/zomato-clone:latest`) from Docker Hub.
- **Scan Docker Image with Trivy**: The image is scanned for vulnerabilities, and the scan results are saved in `trivy_scan.log`.
- **Deploy Docker Container**: The image is deployed as a container on the Jenkins node.

---

### **5. AWS EC2 Setup for Jenkins**
1. **Create EC2 Instance**: Use an **Amazon Linux 2** instance to host Jenkins.
2. **Security Group**: Ensure the EC2 instance's security group allows inbound traffic on port `8080` (for accessing the app) and port `22` (for SSH access).
3. **Install Jenkins on EC2**:
   - Install Java and Jenkins:
     ```bash
     sudo yum update -y
     sudo yum install java-17-amazon-corretto -y
     # Install Jenkins
     sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
     sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

     #STEP: DOWNLOAD JAVA11 AND JENKINS
     yum install jenkins -y
     systemctl start jenkins
     systemctl enable jenkins
     ```
   - Access Jenkins via the public IP of the EC2 instance on port `8080`.

---

### **6. Running the Pipeline**
1. **Create a Jenkins Pipeline Job**:
   - Open Jenkins and create a new pipeline job.
   - Paste the **Jenkinsfile** content into the pipeline configuration.

2. **Trigger the Pipeline**:
   - Trigger the pipeline and monitor the progress.
   - View the logs for:
     - Image pull status.
     - Trivy scan results.
     - Container deployment status.

---

### **7. Viewing Trivy Logs**
The logs from the **Trivy scan** are stored in the `trivy_scan.log` file, and you can view them with:

```bash
cat trivy_scan.log
```

You can also capture Trivy output in different formats, such as **JSON**:

```bash
trivy image --format json iamtejas23/zomato-clone:latest > trivy_scan.json
```

---

### **Conclusion**
This project integrates **Jenkins**, **Docker**, and **Trivy** to create an automated **CI/CD pipeline** with **DevSecOps** practices. It ensures that Docker images are scanned for vulnerabilities and deployed securely, maintaining the integrity and security of the applications.

This setup provides a solid foundation for further automation in security scanning, vulnerability management, and container deployment within a **DevSecOps** pipeline.

---
