# resource "google_service_account" "terraform" {
#   account_id   = "terraform-deployer"
#   display_name = "Terraform Deployer Service Account"
# }

# resource "google_project_iam_member" "terraform_owner" {
#   project = var.project_id
#   role    = "roles/owner"
#   member  = "serviceAccount:${google_service_account.terraform.email}"
# }

# resource "google_service_account_key" "terraform_key" {
#   service_account_id = google_service_account.terraform.name
#   public_key_type    = "TYPE_X509_PEM_FILE"
# }

# output "service_account_key" {
#   value     = google_service_account_key.terraform_key.private_key
#   sensitive = true
# }
