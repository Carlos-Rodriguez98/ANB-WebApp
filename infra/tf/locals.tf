locals {
  name_prefix = "${var.project_name}"
  web_instance_name     = "${local.name_prefix}-web"
  worker_instance_name  = "${local.name_prefix}-worker"
  fileserver_instance_name = "${local.name_prefix}-fileserver"
}