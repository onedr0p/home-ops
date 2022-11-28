# Provider
variable "kubernetes_host" {
  default = "https://192.168.1.81:6443"
  type    = string
}
variable "kubernetes_client_certificate" {
  type = string
}
variable "kubernetes_client_key" {
  type = string
}
variable "kubernetes_cluster_ca_certificate" {
  type = string
}
# App
variable "vector_agent_host" {
  default = "192.168.69.111"
  type    = string
}
variable "vector_agent_port" {
  default = 6000
  type    = number
}
