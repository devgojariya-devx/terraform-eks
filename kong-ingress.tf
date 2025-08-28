resource "kubernetes_ingress_v1" "simple_node_app_ingress" {
  metadata {
    name = "simple-node-app-ingress"
    namespace = kubernetes_namespace.example.metadata[0].name

    annotations = {
      "konghq.com/strip-path" = "true"
    }
  }
  spec {
    ingress_class_name = "kong"

    rule {
      host = "simple-node-app.example.com"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.example.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}