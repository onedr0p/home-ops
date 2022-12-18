variable "kubernetes_host" {
  default = "https://expanse.turbo.ac:6443"
  type    = string
}
variable "nexus_url" {
  default = "http://nexus.turbo.ac"
  type    = string
}
variable "nexus_username" {
  default = "admin"
  type    = string
}
variable "nexus_password" {
  default = "this-is-nothing-important"
  type    = string
}
variable "vector_agent_host" {
  default = "192.168.69.111"
  type    = string
}
variable "vector_agent_port" {
  default = 6000
  type    = number
}
