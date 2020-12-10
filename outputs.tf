output "cluster_name" {
  value = "${module.ecs.cluster_name}"
}

output "service_name" {
  value = "${module.ecs.service_name}"
}

output "listener_arns" {
  value = "${module.ecs.listener_arns}"
}

output "target_group_names" {
  value = "${module.ecs.target_group_names}"
}

output "loadbalancer_dns" {
  value = "${module.ecs.loadbalancer_dns}"
}
