pipeline {
    agent any
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
    }
    triggers { pollSCM('H/2 * * * *') }
    parameters {
        booleanParam(name: 'PUBLISH_RELEASE', defaultValue: true,
            description: 'Publish the explicitly selected manifest version after validation. Existing releases stay unchanged.')
    }
    stages {
        stage('Build environment') {
            steps { sh 'docker build -t enchanted-frames-ci:python313 scripts/ci' }
        }
        stage('Validate and package') {
            steps {
                // Copy through stdin: works with a remote Docker daemon and controller volumes.
                sh '''
                    set -eu
                    container="enchanted-frames-${BUILD_NUMBER}"
                    docker create --name "$container" -e SOURCE_COMMIT="$(git rev-parse HEAD)" enchanted-frames-ci:python313 sh -c 'python scripts/build.py'
                    tar --exclude=.git --exclude=artifacts -cf - . | docker cp - "$container:/workspace"
                    docker start -a "$container"
                    test "$(docker inspect -f '{{.State.ExitCode}}' "$container")" = 0
                    mkdir -p artifacts
                    docker cp "$container:/workspace/artifacts/." artifacts/
                '''
                archiveArtifacts artifacts: 'artifacts/*', fingerprint: true
            }
        }
        stage('Publish release') {
            when { expression { params.PUBLISH_RELEASE } }
            steps {
                withCredentials([usernamePassword(credentialsId: '97c0c8c1-9481-4ed0-b2e9-18b73d7354da', usernameVariable: 'GH_USER', passwordVariable: 'GH_TOKEN')]) {
                    sh 'python3 scripts/publish.py'
                }
            }
        }
    }
    post {
        always { sh 'docker rm -f "enchanted-frames-${BUILD_NUMBER}" >/dev/null 2>&1 || true' }
    }
}
