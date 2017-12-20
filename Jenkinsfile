pipeline {
    agent any
    stages {
        stage('Prerun Diag') {
            steps {
                sh 'pwd'
            }
        }
        stage('Prebuild') {
            steps {
                sh 'cat gawati/gawati_server_setup.sh > /var/www/html/dl.gawati.org/dev/setup'
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'centos:7'
                    args '-v /opt/Download:/opt/Download -u root'
                }
            }
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
curl http://dl.gawati.org/dev/setup -o setup
chmod 755 setup
./setup
./setup
'''
            }
        }
        stage('Upload') {
            steps {
                sh 'ls -la /var/www/html/dl.gawati.org/dev/setup'
            }
        }
        stage('Clean') {
            steps {
                cleanWs(cleanWhenAborted: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, cleanupMatrixParent: true, deleteDirs: true)
            }
        }
    }
}

