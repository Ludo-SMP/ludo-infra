# resource "google_compute_instance" "app" {
#   name         = "ludo-app"
#   machine_type = local.machine_type

#   network_interface {

#   }

#   boot_disk {
#     auto_delete = true
#     initialize_params {
#       image = ""
#     }
#   }

#   network_interface {
#     network    = google_compute_network.main.id
#     subnetwork = google_compute_subnetwork.private.id
#   }

#   metadata_startup_script = <<-EOF
#     docker run -dp 80:8080 ${var.app_image}
#   EOF

# }
