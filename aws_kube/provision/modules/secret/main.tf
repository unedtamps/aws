locals {
  full_secret_name = "${var.cluster_name}/${var.secret_name}"
}


resource "aws_secretsmanager_secret" "app" {
  name                    = local.full_secret_name
  description             = "Secret consumed through External Secrets Operator."
  recovery_window_in_days = 7

  tags = {
    Name      = local.full_secret_name
    Project   = "aws-kube-lab"
    ManagedBy = "OpenTofu"
  }
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    sid    = "EksPodIdentityAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = {
    Name      = "${var.cluster_name}-external-secrets"
    Project   = "aws-kube-lab"
    ManagedBy = "OpenTofu"
  }
}

data "aws_iam_policy_document" "external_secrets_read" {
  statement {
    sid    = "ReadSpecificSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = [
      aws_secretsmanager_secret.app.arn
    ]
  }
}

resource "aws_iam_role_policy" "external_secrets_read" {
  name   = "${var.cluster_name}-external-secrets-read"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets_read.json
}
