resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_project_metadata_item" "ssh_keys" {
  key   = "${var.env}-ssh-keys"
  value = "${google_service_account.bastion_sa.email}:${tls_private_key.bastion.public_key_openssh}"
}

# resource "google_project_iam_custom_role" "ssh_role" {
#   project = var.project_id
#   role_id = "${var.env}-CusomtSshRole"
#   title   = "SSH Role for accessing bastion host"
#   permissions = [
#     "compute.instances.get",
#     "compute.instances.osLogin",
#     "compute.instances.setMetadata",
#     "compute.projects.get",
#     "compute.instances.use",
#   ]
# }

# resource "google_project_iam_member" "ssh_access" {
#   count   = length(var.iam_member_emails)
#   project = var.project_id
#   role    = google_project_iam_custom_role.ssh_role.id
#   member  = "user:${var.iam_member_emails[count.index]}"
# }

# resource "google_project_iam_member" "os_login_users" {
#   count   = length(var.iam_member_emails)
#   project = var.project_id
#   role    = "roles/compute.osLogin"
#   member  = "user:${var.iam_member_emails[count.index]}"
# }

// ssh storage
resource "google_storage_bucket" "ssh_keys_bucket" {
  name     = "${var.env}-ludo-ssh-keys-cloud-bucket-storage"
  location = var.region
}

resource "google_storage_bucket_object" "bastion_ssh_key" {
  name    = "${var.env}-bastion-ssh-key.pem"
  content = tls_private_key.bastion.private_key_pem
  bucket  = google_storage_bucket.ssh_keys_bucket.name
}

resource "google_storage_bucket_object" "private_ssh_key" {
  name    = "${var.env}-private-ssh-key.pem"
  content = tls_private_key.private.private_key_pem
  bucket  = google_storage_bucket.ssh_keys_bucket.name
}

