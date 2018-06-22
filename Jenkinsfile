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
            sh 'python3 -m venv venv'
            sh 'venv/bin/python -m pip install -e $WORKSPACE/oio_rest'
            sh 'venv/bin/python -m pip install -r requirements-test.txt'
          }
        }
      }
    }

    stage('Test MO') {
      steps {
        dir('mora') {
          timeout(15) {
            ansiColor('xterm') {
              sh "venv/bin/python -m pytest --verbose --junitxml=tests.xml tests --junit-prefix=MO"
            }
          }
        }
      }
    }
  }

  post {
    always {
      junit healthScaleFactor: 200.0,           \
        testResults: '*/tests.xml'

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
