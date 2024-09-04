locals {
  project_id        = var.project_id
  region            = var.region
  availability_zone = var.availability_zone
  machine_type      = "e2-micro"

  names = {
    alb = "${var.env}-application-load-balancer"
    app = "${var.env}-app"
    db  = "${var.env}-db-instance"
  }

  subnet_cidr = {
    prod = {
      public  = "10.0.1.0/24"
      private = "10.0.2.0/24"
      db      = "10.0.3.0/24"
    }
    stage = {
      public  = "10.0.7.0/24"
      private = "10.0.8.0/24"
      db      = "10.0.9.0/24"
    }
    test = {
      public  = "10.0.10.0/24"
      private = "10.0.11.0/24"
      db      = "10.0.12.0/24"
    }
  }
  ip = {
    prod = {
      alb     = "10.0.1.2"
      app     = "10.0.2.2"
      db      = "10.0.3.2"
      bastion = "10.0.1.4"
    }
    stage = {
      alb     = "10.0.7.2"
      app     = "10.0.8.2"
      db      = "10.0.9.2"
      bastion = "10.0.7.4"
    }
    test = {
      alb     = "10.0.10.2"
      app     = "10.0.11.2"
      db      = "10.0.12.2"
      bastion = "10.0.10.4"
    }
  }

  internal_dns_names = {
    alb = "${local.names.alb}.${var.availability_zone}.c.${var.project_id}.internal"
    app = "${local.names.app}.${var.availability_zone}.c.${var.project_id}.internal"
    db  = "${local.names.db}.${var.availability_zone}.c.${var.project_id}.internal"
  }
}
