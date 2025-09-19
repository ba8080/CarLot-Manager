pipeline {
  agent any
  stages {
    stage('test') {
      steps {
        echo 'testing will start'
        sh '''echo testing
'''
        sh 'echo again'
      }
    }

    stage('test2') {
      steps {
        sleep 11
        echo 'hi bro'
        sleep 1
      }
    }

  }
}