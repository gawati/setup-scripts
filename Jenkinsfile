pipeline {
    agent any

    triggers {
        upstream(upstreamProjects: 'gawati/gawati-data/dev,gawati/gawati-data-xml/dev,gawati/gawati-portal-server/dev,gawati/gawati-portal-ui/dev,gawati/gawati-templates/dev', threshold: hudson.model.Result.SUCCESS)
    }

    options {
        disableConcurrentBuilds()
    }

//    define {
//      def COLOR_MAP = ['SUCCESS': 'good', 'FAILURE': 'danger', 'UNSTABLE': 'danger', 'ABORTED': 'danger']
//      def STATUS_MAP = ['SUCCESS': 'success', 'FAILURE': 'failed', 'UNSTABLE': 'failed', 'ABORTED': 'failed']
//    }

    stages {
        stage('Prerun Diag') {
            steps {
                sh 'pwd'
                sh '(set -o posix; set)'
            }
        }
        stage('Prebuild') {
            steps {
                sh 'cat gawati/gawati_server_setup.sh > /var/www/html/dl.gawati.org/dev/setup'
            }
        }
        stage('Build') {
            steps {
                sh 'sudo /usr/local/bin/devrefresh "${GIT_BRANCH}"'
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
//            slackSend (color: COLOR_MAP[currentBuild.currentResult], message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}) : updated https://dev.gawati.org")
            slackSend (message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}) : updated https://dev.gawati.org")
        }
        failure {
            slackSend (channel: '#failure', message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        unstable {
            slackSend (channel: '#failure', message: "${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}

