resource "aws_cloudwatch_dashboard" "instances_cpu_dashboard" {
    dashboard_name = "anbapp-instances-cpu"

    dashboard_body = jsonencode({
        widgets = [
            # ================================
            #  CPU Average del Auto Scaling Group
            # ================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/EC2",
                    "CPUUtilization",
                    "AutoScalingGroupName",
                    "${var.project_name}-web-asg",
                    { "stat" : "Average" }
                    ]
                ],
                "view" : "timeSeries",
                "stacked" : false,
                "region" : var.aws_region,
                "title" : "ASG CPU Average (Web)"
                }
            },

            # ================================
            #  Instancias activas (InService) del Auto Scaling Group
            # ================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/AutoScaling",
                    "GroupInServiceInstances",
                    "AutoScalingGroupName",
                    "${var.project_name}-web-asg",
                    { "stat" : "Average" }
                    ]
                ],
                "view" : "timeSeries",
                "stacked" : false,
                "region" : var.aws_region,
                "title" : "Instancias Web Activas en el ASG"
                }
            },

            # -------------------------
            #   CPU Worker Instance
            # -------------------------
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "region" : "us-east-1",
                "title" : "CPU Usage - Worker Instance",
                "period" : 60,
                "stat" : "Average",
                "metrics" : [
                    [
                    "AWS/EC2",
                    "CPUUtilization",
                    "InstanceId",
                    aws_instance.worker.id
                    ]
                ],
                "annotations" : {}
                }
            }
        ]
    })
}