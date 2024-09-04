resource "google_compute_network" "main" {
  name                    = "${var.env}-ludo"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.env}-public"
  ip_cidr_range = local.subnet_cidr[var.env].public
  region        = local.region
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.env}-private"
  ip_cidr_range = local.subnet_cidr[var.env].private
  region        = local.region
  network       = google_compute_network.main.id
}

resource "google_compute_subnetwork" "db" {
  name          = "${var.env}-db"
  ip_cidr_range = local.subnet_cidr[var.env].db
  region        = local.region
  network       = google_compute_network.main.id
}

resource "google_compute_router" "router" {
  name    = "${var.env}-main-router"
  region  = local.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-main-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_internet" {
  name    = "${var.env}-allow-internet"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public"]
}


resource "google_compute_firewall" "allow_public_subnet" {
  name    = "${var.env}-allow-public-internet"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public"]
}
