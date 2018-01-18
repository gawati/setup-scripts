pipeline {
    agent any
    options {
        disableConcurrentBuilds()
        triggers {
            upstream(upstreamProjects: 'gawati-data,gawati-data-xml,gawati-portal-server,gawati-portal-ui,gawati-templates', threshold: hudson.model.Result.SUCCESS)
        }
    }
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
            steps {
                sh 'sudo /usr/local/bin/devrefresh'
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

