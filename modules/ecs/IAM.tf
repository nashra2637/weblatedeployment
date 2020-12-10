resource "aws_iam_role" "execution_role" {
  name               = "${var.name}-${var.environment}-execution-role"
  assume_role_policy = "${data.aws_iam_policy_document.execution_role.json}"
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
