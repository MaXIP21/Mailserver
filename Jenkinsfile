pipeline
{
    agent any
    tools{
        jdk 'jdk22'
        nodejs 'node21'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('Clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/MaXIP21/Mailserver.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Spamfilter \
                    -Dsonar.projectKey=Spamfilter '''
                }
            }
        }
        stage("Quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('Owasp fs scan') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'dp-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('Trivy fs Scan') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'Docker'){   
                       sh "docker build -t spamfilter ."
                       sh "docker tag spamfilter peterb83/spamfilter:latest "
                       sh "docker push peterb83/spamfilter:latest "
                    }
                }
            }
        }
        stage("Trivy"){
            steps{
                sh "trivy image peterb83/spamfilter:latest > trivyimage.txt" 
            }
        }
    }
}