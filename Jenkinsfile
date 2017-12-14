pipeline {
    agent {
        docker {
            image 'centos:7'
            args '-v /opt/Download:/opt/Download'
        }
    }
    stages {
        stage('Prerun Diag') {
            steps {
                sh 'pwd'
            }
        }
        stage('Build') {
            steps {
                sh 'cd ; curl https://gawati.org/setup -o setup ; chmod 755 setup'
                sh './setup'
                sh './setup'
            }
        }
        stage('Upload') {
            steps {
                sh 'cat setup > /var/www/html/dl.gawati.org/dev/setup'
            }
        }
        stage('Clean') {
            steps {
                cleanWs(cleanWhenAborted: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, cleanupMatrixParent: true, deleteDirs: true)
            }
        }
    }
}

