data "github_release" "valetudo" {
    repository  = "Valetudo"
    owner       = "Hypfer"
    retrieve_by = "latest"
}

resource "null_resource" "valetudo" {
  provisioner "local-exec" {
    command = "curl -fsSL -o /tmp/valetudo https://github.com/Hypfer/Valetudo/releases/download/${data.github_release.valetudo.release_tag}/valetudo-armv7"
  }
}

resource "ssh_resource" "valetudo" {
  host              = "192.168.1.28"
  user              = "root"
  agent             = true

  file {
    source      = "/tmp/valetudo"
    destination = "/usr/local/bin/valetudo"
    permissions = "0700"
  }

  commands = [
    "/etc/init/S11valetudo restart"
  ]

  depends_on = [
    null_resource.valetudo
  ]
}
