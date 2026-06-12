package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello CICD v1.0 | Host: %s\n", r.Host)
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(200)
        w.Write([]byte("OK"))
    })
    // 作用：/health 端点给 K8s 做健康检查，CI 做冒烟测试

    http.ListenAndServe(":8080", nil)
}
