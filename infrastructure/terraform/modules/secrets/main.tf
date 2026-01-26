data "aws_secretsmanager_secret" "db" {
  name = var.secret_name
}

data "aws_iam_policy_document" "db_secret_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.ec2_role_arn]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "db_policy" {
  secret_arn = data.aws_secretsmanager_secret.db.arn
  policy     = data.aws_iam_policy_document.db_secret_policy.json
}
