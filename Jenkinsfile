// -*- groovy -*-

pipeline {
  agent any

  environment {
    PYTEST_ADDOPTS = '--color=yes'
  }

  stages {
    stage('Test') {
      steps {
        echo 'Testing oio_rest...'

        timeout(15) {
          ansiColor('xterm') {
            sh 'oio_rest/run_tests.sh'
          }
        }
      }
    }
  }

  post {
    always {
      junit healthScaleFactor: 200.0,           \
        testResults: 'oio_rest/tests.xml'

      warnings canRunOnFailed: true, consoleParsers: [
        [parserName: 'Pep8']
      ]

      cobertura coberturaReportFile: 'oio_rest/coverage.xml',    \
        maxNumberOfBuilds: 0
    }
  }
}
