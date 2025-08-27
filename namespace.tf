resource "kubernetes_namespace" "example" {
  metadata {
    name = "simple-node-app"
  }
}