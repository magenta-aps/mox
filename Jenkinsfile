// -*- groovy -*-

pipeline {
  agent any

  environment {
    PYTEST_ADDOPTS = '--color=yes'
  }

  stages {
    stage('Docs') {
      steps {

        timeout(2) {
          ansiColor('xterm') {
            sh 'make -C doc dirhtml'
          }
        }

        publishHTML target: [
          allowMissing: true, reportDir: 'doc/_build/dirhtml',
          reportFiles: 'index.html', reportName: 'Docs'
        ]
      }
    }
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
        [parserName: 'Sphinx-build'],
        [parserName: 'Pep8']
      ]

      cobertura coberturaReportFile: 'oio_rest/coverage.xml',    \
        maxNumberOfBuilds: 0
    }
  }
}
