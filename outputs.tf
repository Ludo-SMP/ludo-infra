output "db_internal_dns" {
#   value = "${google_compute_instance.app.name}.${google_compute_instance.app.zone}.c.${var.project_id}.internal"
  value = local.internal_dns_names.db
}

output "alb_internal_dns" {
  value = local.internal_dns_names.alb
}

output "app_internal_dns" {
  value = local.internal_dns_names.app
}
# output "app_external_ip" {
#   value = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
# }

