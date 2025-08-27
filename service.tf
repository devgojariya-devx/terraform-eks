resource "kubernetes_service" "example" {
  metadata {
    name      = "simple-node-app-service"
    namespace = kubernetes_namespace.example.metadata[0].name
  }
  spec {
    selector = {
      app = "simple-node-app"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}