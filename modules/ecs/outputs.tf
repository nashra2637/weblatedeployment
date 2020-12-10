output "cluster_name" {
  value = "${aws_ecs_cluster.weblate.name}"
}

output "service_name" {
  value = "${aws_ecs_service.weblate.name}"
}

output "listener_arns" {
  value = "${aws_lb_listener.weblate_listener.*.arn}"
}

output "target_group_names" {
  value = "${aws_lb_target_group.weblate_tg.*.name}"
}

output "loadbalancer_dns" {
  value = "${aws_lb.weblate.dns_name}"
}

