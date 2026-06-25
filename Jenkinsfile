pipeline {
    agent any
    triggers { pollSCM('* * * * *') }
    // 解释：每分钟检查 GitHub 是否有新提交
    //       GitHub Actions 用 on: push 自动触发，Jenkins 需要 pollSCM 或 Webhook

    environment {
        HARBOR_URL  = '192.168.1.158:30002'
        HARBOR_PROJ = 'demo'
        IMAGE_NAME  = 'demo-app'
    }

    stages {
        stage('Checkout') {
            // GitHub Actions: - uses: actions/checkout@v4
            steps { checkout scm }
        }

        stage('Build & Scan') {
            // GitHub Actions: 不同 Job 自动并行 Executor: 需要显式 parallel
            parallel {
                stage('Build Image') {
                    steps {
                        script { env.IMAGE_TAG = "${BUILD_NUMBER}" }
                        sh "docker build -t ${HARBOR_URL}/${HARBOR_PROJ}/${IMAGE_NAME}:${IMAGE_TAG} ."
                    }
                }
                stage('Trivy Scan') {
                    steps {
                        sh """
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                              aquasec/trivy image --severity HIGH,CRITICAL --exit-code 0 \
                              ${HARBOR_URL}/${HARBOR_PROJ}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Push to Harbor') {
            // GitHub Actions: docker login + docker push
            // Jenkins: docker.withRegistry() 自动管理凭据
            steps {
                script {
                    docker.withRegistry("http://${HARBOR_URL}", 'harbor-credentials') {
                        sh "docker push ${HARBOR_URL}/${HARBOR_PROJ}/${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                sh """
                    kubectl set image deployment/demo-app \
                      demo-app=${HARBOR_URL}/${HARBOR_PROJ}/${IMAGE_NAME}:${IMAGE_TAG} \
                      -n default
                    kubectl rollout status deployment/demo-app -n default --timeout=120s
                """
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    for i in 1 2 3; do
                        STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                          http://demo-app-svc.default/health)
                        if [ "$STATUS" = "200" ]; then
                            echo "冒烟测试通过"
                            exit 0
                        fi
                        sleep 3
                    done
                    exit 1
                '''
            }
        }
    }

    post {
        success { echo "流水线成功: ${IMAGE_TAG}" }
        failure { echo "流水线失败" }
    }
}
