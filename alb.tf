resource "google_compute_instance" "alb" {
  name         = local.names.alb
  machine_type = local.machine_type
  zone         = local.availability_zone

  tags = ["alb"]

  boot_disk {
    initialize_params {
      # image = "cos-cloud/cos-stable"
      image = "debian-cloud/debian-12"
    }
  }
  allow_stopping_for_update = true

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      nat_ip = google_compute_address.alb.address
    }
    network_ip = local.ip[var.env].alb
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ludo:${tls_private_key.private.public_key_openssh}"
  }

  # metadata_startup_script = <<-EOF
  #   docker run -dp 80:80 --name alb \
  #   -e BACKEND_URL=10.0.2.2 \
  #   ${var.nginx_image}
  # EOF
  metadata_startup_script = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install -y nginx

  # Write the nginx.conf file content with placeholder
  cat <<EOT > /tmp/nginx.conf
  worker_processes auto;

  error_log /var/log/nginx/error.log notice;

  events {
      worker_connections 1024;
  }

  http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;

      sendfile on;
      keepalive_timeout 65;

      upstream backend {
          server ${local.ip[var.env].app}${var.app_port};
      }

      upstream frontend {
        server ${var.frontend_url};
      }

      server {
          listen 80;
          server_name localhost;

          location /api {
              proxy_pass http://backend;
              proxy_set_header Host \$host;
              proxy_set_header X-Real-IP \$remote_addr;
              proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

              proxy_buffering off;
              proxy_set_header Connection '';
              chunked_transfer_encoding off;
          }

          location / {
              proxy_pass http://frontend;
              proxy_set_header Host \$host;
              proxy_set_header X-Real-IP \$remote_addr;
              proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

              proxy_buffering off;
              proxy_set_header Connection '';
              chunked_transfer_encoding off;
          }
      }
  }
  EOT

  # Move the modified configuration to the correct location
  mv /tmp/nginx.conf /etc/nginx/nginx.conf

  # Restart nginx to apply the new configuration
  systemctl restart nginx
EOF

}

resource "google_compute_firewall" "allow_alb_from_bastion" {
  name    = "${var.env}-allow-alb-from-bastion"
  network = google_compute_network.main.name

  source_tags = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

}
resource "google_compute_firewall" "allow_alb_from_internet" {
  name    = "${var.env}-allow-alb-from-internet"
  network = google_compute_network.main.name

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "icmp"
  }

}

resource "google_compute_address" "alb" {
  name   = "${var.env}-alb-ip"
  region = var.region
}
