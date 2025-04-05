pipeline {
    agent any
    
    // tools {
    //     terraform 'terraform'
    // }
    
    environment {
        AWS_CREDENTIALS = 'aws-credentials'
        SSH_CREDENTIALS = 'ec2-ssh-key'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${env.AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        sh 'terraform init'
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${env.AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }
        
        stage('Approval') {
            steps {
                input message: 'Do you want to apply this plan?', ok: 'Apply'
            }
        }
        
        stage('Terraform Apply') {
    steps {
        withCredentials([
            [
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: "${env.AWS_CREDENTIALS}",
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ],
            sshUserPrivateKey(credentialsId: "${env.SSH_CREDENTIALS}", keyFileVariable: 'SSH_KEY')
        ]) {
            dir('terraform') {
                sh 'terraform apply -auto-approve tfplan -var="ssh_private_key_path=${SSH_KEY}"'
            }
        }
    }
}
        
        stage('Ansible Provision') {
            steps {
                // Wait for a moment to ensure the EC2 instance is fully initialized
                sh 'sleep 60'
                
                withCredentials([sshUserPrivateKey(credentialsId: "${env.SSH_CREDENTIALS}", keyFileVariable: 'SSH_KEY')]) {
                    dir('ansible') {
                        sh 'ansible-playbook -i inventory jenkins-playbook.yml --private-key=${SSH_KEY}'
                    }
                }
            }
        }
        
        stage('Get Jenkins URL') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${env.AWS_CREDENTIALS}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        script {
                            def jenkinsUrl = sh(script: 'terraform output -raw jenkins_url', returnStdout: true).trim()
                            echo "Jenkins has been deployed at: ${jenkinsUrl}"
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Jenkins deployment successful!'
        }
        failure {
            echo 'Jenkins deployment failed. Check logs for details.'
        }
    }
}