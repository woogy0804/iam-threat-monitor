# 이번 단계의 이름과 태그를 한곳에서 관리한다.
locals {
  trail_name = "iam-threat-monitor"
  trail_arn  = "arn:aws:cloudtrail:us-east-1:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"

  project_tags = {
    Project   = "iam-threat-monitor"
    ManagedBy = "Terraform"
  }
}

# S3 버킷은 CloudTrail 원본 로그 파일을 보관하는 공간이다.
# 계정 ID를 붙여 전 세계에서 고유해야 하는 버킷 이름의 충돌을 줄인다.
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "iam-threat-monitor-trail-${data.aws_caller_identity.current.account_id}-us-east-1"
  force_destroy = false
  tags          = local.project_tags
}

# 로그가 공개되지 않도록 버킷의 공개 액세스를 차단한다.
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 저장 파일은 S3 관리 키로 암호화한다. 별도 KMS 키는 만들지 않는다.
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail 서비스가 이 추적의 로그만 지정 경로에 기록하도록 허용한다.
data "aws_iam_policy_document" "cloudtrail_logs" {
  statement {
    sid       = "CloudTrailBucketAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "CloudTrailLogWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json
}

# us-east-1 단일 리전 추적에 IAM 같은 글로벌 서비스 이벤트를 포함한다.
# 첫 시나리오에 필요한 쓰기 관리 이벤트를 기록한다.
# 두 API만 기록하는 것은 아니며, API별 선별은 이후 EventBridge가 담당한다.
resource "aws_cloudtrail" "management" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = false
  is_organization_trail         = false
  enable_log_file_validation    = true
  tags                          = local.project_tags

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_s3_bucket_public_access_block.cloudtrail_logs,
    aws_s3_bucket_server_side_encryption_configuration.cloudtrail_logs,
  ]
}

output "cloudtrail_name" {
  description = "로그 수집에 사용할 CloudTrail 추적 이름"
  value       = aws_cloudtrail.management.name
}

output "cloudtrail_bucket_name" {
  description = "CloudTrail 원본 로그를 보관할 S3 버킷 이름"
  value       = aws_s3_bucket.cloudtrail_logs.id
}
