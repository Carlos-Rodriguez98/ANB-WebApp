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

            # =====================================
            # Lambda — Concurrence Used
            # =====================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/Lambda",
                    "ConcurrentExecutions",
                    "FunctionName",
                    "${var.project_name}-worker-lambda",
                    { "stat" : "Maximum" }
                    ]
                ],
                "view" : "timeSeries",
                "stacked" : false,
                "region" : var.aws_region,
                "title" : "Lambda Concurrent Executions"
                }
            },

            # =====================================
            # Lambda — Invocations
            # =====================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/Lambda",
                    "Invocations",
                    "FunctionName",
                    "${var.project_name}-worker-lambda",
                    { "stat" : "Sum" }
                    ]
                ],
                "view" : "timeSeries",
                "stacked" : false,
                "region" : var.aws_region,
                "title" : "Lambda Invocations"
                }
            },

            # =====================================
            # Lambda — Duration Average
            # =====================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/Lambda",
                    "Duration",
                    "FunctionName",
                    "${var.project_name}-worker-lambda",
                    { "stat" : "Average" }
                    ]
                ],
                "view" : "timeSeries",
                "region" : var.aws_region,
                "title" : "Lambda Duration (ms)"
                }
            },

            # =====================================
            # Lambda — Errors
            # =====================================
            {
                "type" : "metric",
                "width" : 12,
                "height" : 6,
                "properties" : {
                "metrics" : [
                    [
                    "AWS/Lambda",
                    "Errors",
                    "FunctionName",
                    "${var.project_name}-worker-lambda",
                    { "stat" : "Sum" }
                    ]
                ],
                "view" : "timeSeries",
                "region" : var.aws_region,
                "title" : "Lambda Errors"
                }
            },
        ]
    })
}