locals {
  name_prefix = "ytsumm-prd"

  common_tags = {
    Environment = "prod"
    Project     = "shared-infra"
    ManagedBy   = "terraform"
  }
}
