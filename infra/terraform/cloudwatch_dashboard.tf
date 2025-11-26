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
            }

            # -------------------------
            #   CPU Promedio - ASG Worker
            # -------------------------
            # {
            #     "type": "metric",
            #     "width": 12,
            #     "height": 6,
            #     "properties": {
            #         "metrics": [
            #         [
            #             "AWS/EC2",
            #             "CPUUtilization",
            #             "AutoScalingGroupName",
            #             "${var.project_name}-worker-asg",
            #             { "stat": "Average" }
            #         ]
            #         ],
            #         "view": "timeSeries",
            #         "stacked": false,
            #         "region": var.aws_region,
            #         "title": "ASG CPU Average (Worker)"
            #     }
            # },

            # -------------------------
            #   Instancias activas (InService) - ASG Worker
            # -------------------------
            # {
            #     "type": "metric",
            #     "width": 12,
            #     "height": 6,
            #     "properties": {
            #         "metrics": [
            #         [
            #             "AWS/AutoScaling",
            #             "GroupInServiceInstances",
            #             "AutoScalingGroupName",
            #             "${var.project_name}-worker-asg",
            #             { "stat": "Average" }
            #         ]
            #         ],
            #         "view": "timeSeries",
            #         "stacked": false,
            #         "region": var.aws_region,
            #         "title": "Instancias Worker Activas en el ASG"
            #     }
            # }
        ]
    })
}