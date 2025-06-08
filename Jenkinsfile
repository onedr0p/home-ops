def cliVersion = "1.0.1"
def cliFile = "kustomtrace-cli-${cliVersion}-all.jar"
def cliUrl = "https://github.com/zucca-devops-tooling/kustom-trace/releases/download/v${cliVersion}/${cliFile}"
def appListFile = "apps.yaml"
def builtAppsFolder = "kustomize-output"
def policiesFile = "policies.yaml"
def kyvernoResults = "results.yaml"

pipeline {
    agent any

    environment {
        GRADLE_OPTS = '-Dorg.gradle.jvmargs="-Xmx2g -XX:+HeapDumpOnOutOfMemoryError"'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Download kustom-trace-cli') {
            steps {
                script {
                    sh "curl -LO ${cliUrl}"
                }
            }
        }
        stage('Get apps to build') {
            steps {
                script {
                    sh "java -jar ${cliFile} list-root-apps -a ./kubernetes -o ${appListFile}"
                }
            }
        }
        stage('Build apps') {
            steps {
                script {
                    def apps = readYaml file: appListFile
                    kustomize-output
                    sh "mkdir ${builtAppsFolder}"

                    if (apps && apps.'root-apps') {
                        apps.'root-apps'.each { appPath ->
                            def outputFile = builtAppsFolder + "/" + appPath.replaceAll("/", "_")
                            echo "--- Executing build for: ${appPath} ---"
                            sh "kustomize build ${appPath} -o ${outputFile}"
                        }
                    }
                }
            }
        }
        stage('Build kyverno policies') {
            steps {
                script {
                    sh "kustomize build ./policies -o ${policiesFile}"
                }
            }
        }
        stage('Apply kyverno policies') {
            steps {
                script {
                    sh "kyverno apply ${policiesFile} --resource ${builtAppsFolder} --audit-warn -o ${kyvernoResults}"
                }
            }
            post {
                success {
                    script {
                        if (fileExists(kyvernoResults)) {
                            archieveArtifacts artifacts: "${kyvernoResults}"
                        }
                    }
                }
            }
        }
        post {
            always {
                cleanup {
                    deleteDir()
                }
            }
        }
    }
}
