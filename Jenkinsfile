pipeline {
    agent any
    triggers {
        upstream(upstreamProjects: 'gawati-data,gawati-data-xml,gawati-portal-server,gawati-portal-ui,gawati-templates', threshold: hudson.model.Result.SUCCESS)
    }
    options {
        disableConcurrentBuilds()
    }
    define {
      def COLOR_MAP = ['SUCCESS': 'good', 'FAILURE': 'danger', 'UNSTABLE': 'danger', 'ABORTED': 'danger']
      def STATUS_MAP = ['SUCCESS': 'success', 'FAILURE': 'failed', 'UNSTABLE': 'failed', 'ABORTED': 'failed']
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
    post {
        always {
            slackSend (color: COLOR_MAP[currentBuild.currentResult], message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}) : updated https://dev.gawati.org")
        }
    }
}

