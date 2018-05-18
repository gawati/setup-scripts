pipeline {
    agent any

    triggers {
        upstream(upstreamProjects: 'gawati/gawati-client-data/master,gawati/gawati-editor-fe/master,gawati/gawati-editor-ui/master,gawati/gawati-data/master,gawati/gawati-data-xml/master,gawati/gawati-portal-fe/master,gawati/gawati-portal-ui/master,gawati/gawati-templates/master,gawati/gawati-profiles-fe/master,gawati/gawati-workflow/master', threshold: hudson.model.Result.SUCCESS)
    }

    options {
        disableConcurrentBuilds()
    }

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

