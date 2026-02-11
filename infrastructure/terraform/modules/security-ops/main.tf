/*
==============================================================================
Security Ops Module: Detection and Response Infrastructure
==============================================================================
Provisions security operations components:
- CloudTrail for API audit logging (S3 delivery)
- GuardDuty and Security Hub for threat detection (planned)
- EventBridge and Lambda for automated incident response (planned)
==============================================================================
*/

# CloudTrail Initialization
resource "aws_cloudtrail" "this" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]

  name                          = "${var.project}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
}

# S3 Bucket for CloudTrail log delivery
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project}-cloudtrail-logs"
  force_destroy = true
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy granting CloudTrail permission to deliver logs
data "aws_iam_policy_document" "cloudtrail_s3_access" {
  statement {
    sid    = "AWSCloudTrailACLCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.project}-cloudtrail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.project}-cloudtrail"]
    }
  }
}

# S3 Bucket Policy attachment for CloudTrail Logs
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_s3_access.json
}
