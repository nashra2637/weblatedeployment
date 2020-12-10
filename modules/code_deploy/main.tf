resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "ECS"
  name             = "${var.name}-${var.environment}-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "codedeploy_dg" {
  app_name               = "${aws_codedeploy_app.codedeploy_app.name}"
  deployment_group_name  = "${var.name}-${var.environment}-dg"
  service_role_arn       = "${aws_iam_role.code_deploy.arn}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

#   auto_rollback_configuration {
#     enabled = "${var.auto_rollback_enabled}"
#     events = ["${var.auto_rollback_events}"]
#   }

  blue_green_deployment_config {    
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = "0"
    }
  

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = "${var.termination_wait_time_in_minutes}"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${var.ecs_cluster_name}"
    service_name = "${var.ecs_service_name}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${element(var.lb_listener_arns, 0)}"]
      }

      target_group {
        name = "${var.blue_lb_target_group_name}"
      }

      target_group {
        name = "${var.green_lb_target_group_name}"
      }

    #   test_traffic_route {
    #     listener_arns = ["${var.test_traffic_route_listener_arns}"]
    #   }
    }
  }
}

