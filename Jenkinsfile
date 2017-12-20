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
                sh '''id
pwd
ls /
ls /root
cd
pwd
docker ps -a
'''
            }
        }
        stage('Build') {
            steps {
                sh '''id
pwd
ls /
ls /root
cd
pwd
docker ps -a
su -
id
cd
pwd
ls
'''
                sh '''cd
curl https://gawati.org/setup -o setup ; chmod 755 setup
./setup
./setup
'''
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

