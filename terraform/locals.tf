locals {
  name_prefix = "ytsumm-prd-ci"

  common_tags = {
    Environment = "prod"
    Project     = "shared-infra"
    ManagedBy   = "terraform"
  }
}
