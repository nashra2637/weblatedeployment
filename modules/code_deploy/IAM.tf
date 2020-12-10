resource "aws_iam_role" "code_deployk" {
  name               = "${var.name}-${var.environment}-codedeploy-role"
  assume_role_policy = "${data.aws_iam_policy_document.code_deploy_policy.json}"
  path               = "/"
  tags = {
    Name        = "${var.name}-${var.environment}-codedeploy-role"
    Environment = "${var.environment}"
  }
}

data "aws_iam_policy_document" "code_deploy_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codedeploy_policy" {
  name        = "${var.name}-${var.environment}-codedeploy-policy"
  policy      = "${data.aws_iam_policy_document.codedeploy_policy_doc.json}"
  path        = "/"
}

data "aws_iam_policy_document" "codedeploy_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
      "cloudwatch:DescribeAlarms",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = ["arn:aws:sns:*:*:CodeDeployTopic_*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = ["arn:aws:lambda:*:*:function:CodeDeployHook_*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectMetadata",
      "s3:GetObjectVersion",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/UseWithCodeDeploy"
      values   = ["true"]
    }

    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "codedeploy_attachment" {
  role       = "${aws_iam_role.code_deploy.name}"
  policy_arn = "${aws_iam_policy.codedeploy_policy.arn}"
}
