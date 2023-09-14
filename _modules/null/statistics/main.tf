locals {
  host      = "https://hh5n8k57bh.execute-api.us-east-1.amazonaws.com"
  resource  = "dsfkit_usage_stats"
  stage     = "dev"
  url       = join("/", [local.host, local.stage, local.resource])
  header_value = base64decode("amxEU0NhRWwyTTc2NkZVWUtVTFhlNUxyRVpBYVR4akhHd0dGYkExYg==")
  
  id = var.id == null ? random_uuid.stats_id.result : var.id

  enable_statistics = true
}

resource "random_uuid" "stats_id" {
}

locals {
  payload = jsonencode({
    "id" : local.id
    "deployment_name" : var.deployment_name,
    "artifact" : var.artifact
    "product" : var.product
    "resource_type" : var.resource_type
    "platform" : var.platform
    "account_id" : sha256(var.account_id)
    "location" : var.location
    "initialization_status" : var.initialization_status
    "additional_info" : var.additional_info
  })
}

resource "null_resource" "curl_request" {
  count = local.enable_statistics ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
              curl -X POST \
                  -H "Content-Type: application/json" \
                  -H "x-api-key: ${local.header_value}" \
                  --data '${local.payload}' \
                  '${local.url}' || true
              EOT
  }

  triggers = {
    url          = local.url
    data_payload = local.payload
  }
}

## http data source can fail resulting a user's deployment to fail. That's why we prefer to use curl directly with 
# data "http" "statistics" {
#   url    = local.url
#   method = "POST"

#   request_headers = {
#     Accept    = "application/json"
#     x-api-key = local.header_value
#   }

#   request_body = local.payload
#   ignore_errors = true
# }