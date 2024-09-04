resource "google_compute_instance" "db" {
  name         = local.names.db
  machine_type = local.machine_type
  zone         = var.availability_zone

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  allow_stopping_for_update = true

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.db.id
    network_ip = local.ip[var.env].db
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    mkdir -p /mnt/stateful_partition/mysql-data

    if mount | grep -q '/mnt/stateful_partition/mysql-data'; then
      echo "Disk is already mounted."
    else
      if [ -e /dev/disk/by-id/google-mysql-disk ]; then
        mount -o discard,defaults /dev/disk/by-id/google-mysql-disk /mnt/stateful_partition/mysql-data
      else
        /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/disk/by-id/google-mysql-disk /mnt/stateful_partition/mysql-data
      fi
    fi
    docker run -d \
        --name mysql \
        -p 3306:3306 \
        -e MYSQL_ROOT_PASSWORD=${var.db_password} \
        -e MYSQL_DATABASE=${var.db_name} \
        -e MYSQL_USER=${var.db_username} \
        -e MYSQL_PASSWORD=${var.db_password} \
        -v /mnt/stateful_partition/mysql-data:/var/lib/mysql \
        mysql:8.0
  EOF

  attached_disk {
    source      = google_compute_disk.mysql_disk.id
    device_name = "${var.env}-mysql-disk"
    mode        = "READ_WRITE"

  }


  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = "ludo:${tls_private_key.private.public_key_openssh}"
  }

  tags = ["mysql", "db"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "allow_db_from_private" {
  name    = "${var.env}-allow-mysql-from-private"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = [google_compute_subnetwork.private.ip_cidr_range]
  target_tags   = ["mysql"]

}


resource "google_compute_firewall" "allow_db_from_bastion_3306" {
  name    = "${var.env}-allow-mysql-from-bastion-3306"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_tags = ["bastion"]
  target_tags = ["db"]

}

resource "google_compute_firewall" "allow_db_from_bastion" {
  name    = "${var.env}-allow-mysql-from-bastion"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["bastion"]
  target_tags = ["db"]

}

resource "google_compute_disk" "mysql_disk" {
  name = "${var.env}-mysql-disk"
  type = "pd-ssd"
  zone = var.availability_zone
  size = var.disk_size_gb

  physical_block_size_bytes = 4096
  lifecycle {
    # prevent_destroy = true
  }

}



# resource "google_sql_database_instance" "mysql" {
#   name             = "ludo-db"
#   database_version = "MYSQL_8_0"
#   region           = local.region

#   settings {
#     tier = "db-f1-micro"

#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = google_compute_network.main.id
#     }
#   }

#   deletion_protection = false
# }

# resource "google_sql_database" "mysql" {
#   name     = var.db_name
#   instance = google_sql_database_instance.mysql.name
# }

# resource "google_compute_global_address" "db_private" {
#   name          = "db-private-address"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = google_compute_network.main.id
# }

# resource "google_service_networking_connection" "private_vpc_conn" {
#   network                 = google_compute_network.main.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.db_private.name]
# }

# resource "google_compute_firewall" "allow_db_access" {
#   name    = "allow-db-access"
#   network = google_compute_network.main.id

#   allow {
#     protocol = "tcp"
#     ports    = ["3306"]
#   }

#   source_ranges = [google_compute_subnetwork.private.ip_cidr_range]
#   target_tags   = ["db"]
# }

# resource "google_sql_database" "database" {
#   name     = var.db_name
#   instance = google_sql_database_instance.mysql.name
# }

# resource "google_sql_user" "users" {
#   name     = var.db_username
#   instance = google_sql_database_instance.mysql.name
#   password = var.db_password
# }
