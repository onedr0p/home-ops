terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "4.15.1"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "0.4.0"
    }
  }
}

provider "ssh" {
  debug_log = "/tmp/ssh.log"
}
