locals {
  project_id = "print-money-1543"
  timestamp = formatdate("YYMMDDhhmmss", timestamp())
  root_dir = abspath("../src/")
  function_entry_point = "main"
}


variable "billing_account" {
    type = string
}


resource "google_project" "print-money" {
  name       = "Print Money"
  project_id = local.project_id
  billing_account = var.billing_account
}

provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}


# Compress source code
data "archive_file" "source" {
  type        = "zip"
  source_dir  = local.root_dir
  output_path = "/tmp/function-${local.timestamp}.zip"
}

# Create bucket that will host the source code
resource "google_storage_bucket" "src" {
  name = "${local.project_id}-function"
  location = "US"
  storage_class = "standard"

   lifecycle {
       prevent_destroy = true
    }
}

# Add source code zip to bucket
resource "google_storage_bucket_object" "zip" {
  # Append file MD5 to force bucket to be recreated
  name   = "source.zip#${data.archive_file.source.output_md5}"
  bucket = google_storage_bucket.src.name
  source = data.archive_file.source.output_path
}

# Enable Cloud Functions API
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "10.1.1"

  project_id = local.project_id

  activate_apis = [
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com"
  ]
  disable_dependent_services = true
  disable_services_on_destroy = false
}


resource "google_storage_bucket" "output" {
    # project = local.project_id
    name = "${local.project_id}-print-money"
    location = "US"
    storage_class = "standard"
}

resource "google_pubsub_topic" "money_trigger" {
    name = "${local.project_id}-money_trigger"
}

# Create Cloud Function
resource "google_cloudfunctions_function" "function" {
    name    = "func_money"
    description = "Function to print money"
    runtime = "python38"

    available_memory_mb   = 128
    source_archive_bucket = google_storage_bucket.src.name
    source_archive_object = google_storage_bucket_object.zip.name
    event_trigger {
        event_type = "google.pubsub.topic.publish"
        resource = google_pubsub_topic.money_trigger.name
    }
    entry_point           = local.function_entry_point
}

# google_cloud_scheduler_job requires app engine application.
resource "google_app_engine_application" "app" {
  location_id = "us-central"
}


resource "google_cloud_scheduler_job" "job" {
  name        = "mon_printing_func"
  description = "schedule money printing job"
  schedule    = "* * * * *"
  time_zone   = "America/New_York"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.money_trigger.id
    data       = base64encode("test")
  }
}