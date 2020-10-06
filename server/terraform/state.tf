terraform {
  backend "gcs" {
    bucket = "vdh-exposure-notifier-tf-state"
  }
}
