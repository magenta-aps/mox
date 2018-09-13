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
            sh 'make -C doc dirhtml SPHINXOPTS=--color'
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
        timeout(15) {
          ansiColor('xterm') {
            sh 'oio_rest/run_tests.sh'
          }
        }
      }
    }

    stage('Fetch MO') {
      steps {
        dir('mora') {
          git url: 'https://github.com/magenta-aps/mora', branch: 'development'

          timeout(5) {
            sh 'backend/.jenkins/1-build.sh'

            // kind of horrible, but works
            sh 'echo $WORKSPACE/oio_rest > venv/lib/python3.5/site-packages/oio_rest.egg-link'
          }
        }
      }
    }

    stage('Test MO') {
      steps {
        dir('mora/backend') {
          timeout(15) {
            ansiColor('xterm') {
              sh '.jenkins/3-tests.sh'
            }
          }
        }

        sh 'find $WORKSPACE -name "*.xml"'
      }
    }
  }

  post {
    always {
      junit healthScaleFactor: 200.0,           \
        testResults: '**/build/reports/*.xml'

      warnings canRunOnFailed: true, consoleParsers: [
        [parserName: 'Sphinx-build'],
        [parserName: 'Pep8']
      ]

      cobertura coberturaReportFile: 'oio_rest/coverage.xml',    \
        maxNumberOfBuilds: 0

      cleanWs()
    }
  }
}
