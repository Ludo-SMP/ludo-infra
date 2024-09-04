# app instance running on docker
resource "google_compute_instance" "app" {
  name         = local.names.app
  machine_type = local.machine_type
  zone         = local.availability_zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  tags                      = ["app"]
  allow_stopping_for_update = true

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.private.id
    network_ip = local.ip[var.env].app
    # no pub ip addr
    # access_config {
    # }
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ludo:${tls_private_key.private.public_key_openssh}"
  }

  metadata_startup_script = <<-EOF
    docker run -d --name app -p 80:${var.app_port} \
        -e DB_URL="jdbc:mysql://${local.ip[var.env].db}:3306/${var.db_name}" \
        -e DB_NAME=${var.db_name} \
        -e DB_USERNAME=${var.db_username} \
        -e DB_PASSWORD=${var.db_password} \
        ${var.app_image}
  EOF
}

resource "google_compute_firewall" "allow_app_from_alb" {
  name    = "${var.env}-allow-app-from-alb"
  network = google_compute_network.main.name

  source_tags = ["alb"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

}

resource "google_compute_firewall" "allow_app_from_bastion" {
  name    = "${var.env}-allow-app-from-bastion"
  network = google_compute_network.main.name

  source_tags = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }


}

