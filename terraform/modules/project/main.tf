resource "google_project" "print-money" {
  name       = "Print Money"
  project_id = var.project_id
  billing_account = var.billing_account
}