data "google_iam_policy" "bastion_iam_policy" {
  binding {
    role = "roles/compute.osAdminLogin"
    members = [
      for email in var.iam_member_emails :
      "user:${email}"
    ]
  }

}
resource "google_compute_instance" "bastion" {
  name         = "${var.env}-bastion-host"
  machine_type = "e2-micro"
  zone         = var.availability_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  allow_stopping_for_update = true

  network_interface {
    network    = google_compute_network.main.self_link
    subnetwork = google_compute_subnetwork.public.self_link

    network_ip = local.ip[var.env].bastion

    access_config {
      nat_ip = google_compute_address.bastion.address
    }
  }

  service_account {
    email  = google_service_account.bastion_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ludo:${tls_private_key.bastion.public_key_openssh}"
    # Startup script to modify /etc/hosts
    user-data = <<-EOF
          #!/bin/bash
      
      # SSH 키 파일 생성
      echo '${tls_private_key.private.private_key_pem}' > /home/ludo/.ssh/id_rsa
      chmod 600 /home/ludo/.ssh/id_rsa
      
      # .bashrc에 alias 추가
      echo "# Custom SSH aliases" >> /home/ludo/.bashrc
      echo "alias conn_alb='ssh ludo@${google_compute_instance.alb.network_interface[0].network_ip}'" >> /home/ludo/.bashrc
      echo "alias conn_app='ssh ludo@${google_compute_instance.app.network_interface[0].network_ip}'" >> /home/ludo/.bashrc
      echo "alias conn_db='ssh ludo@${google_compute_instance.db.network_interface[0].network_ip}'" >> /home/ludo/.bashrc
      
      # 소유권 및 권한 설정
      chown -R ludo:ludo /home/ludo/.ssh /home/ludo/.bashrc
      chmod 700 /home/ludo/.ssh
    EOF
  }

  tags = ["bastion"]

}

# resource "google_compute_instance_iam_policy" "bastion_iam" {
#   project       = var.project_id
#   zone          = var.availability_zone
#   instance_name = google_compute_instance.bastion.name
#   policy_data   = data.google_iam_policy.bastion_iam_policy.policy_data
# }
# # # IAP를 통한 SSH 접근을 위한 방화벽 규칙
# # resource "google_compute_firewall" "iap_to_bastion" {
# #   name    = "allow-iap-to-bastion"
# #   network = data.google_compute_network.vpc.name

# #   allow {
# #     protocol = "tcp"
# #     ports    = ["22"]
# #   }

# #   source_ranges = ["35.235.240.0/20"] # IAP의 IP 범위
# #   target_tags   = ["bastion"]
# # }

# resource "google_project_iam_member" "iap_tunnel_users" {
#   count   = length(var.iam_member_emails)
#   project = var.project_id
#   role    = "roles/compute.osLogin"
#   member  = "user:${var.iam_member_emails[count.index]}"
# }

# # IAP 사용을 위한 IAM 권한 설정
# resource "google_project_iam_member" "iap_tunnel_user" {
#   count   = length(var.iam_member_emails)
#   project = var.project_id
#   role    = "roles/iap.tunnelResourceAccessor"
#   member  = "user:${var.iam_member_emails[count.index]}"
# }

resource "google_service_account" "bastion_sa" {
  account_id   = "${var.env}-bastion-sa"
  display_name = "Bastion SA"
}


resource "google_compute_firewall" "allow_bastion_from_internet" {
  name    = "${var.env}-allow-bastion-from-internet"
  network = google_compute_network.main.name

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "icmp"
  }

}

resource "google_compute_address" "bastion" {
  name   = "${var.env}-bastion-ip"
  region = var.region
}

