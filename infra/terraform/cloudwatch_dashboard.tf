resource "aws_cloudwatch_dashboard" "main_dashboard" {
    dashboard_name = "${var.project_name}-dashboard"

    dashboard_body = jsonencode({
        widgets = [

        # CPU del ASG Web
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
            "title": "CPU - ASG Web",
            "region": var.aws_region,
            "metrics": [
                [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name ]
            ],
            "stat": "Average",
            "period": 60,
            "annotations": {
                "horizontal": []
            }
            }
        },

        # Instancias activas ASG Web
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
            "title": "Instancias InService - ASG Web",
            "region": var.aws_region,
            "metrics": [
                [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.web.name ]
            ],
            "stat": "Average",
            "period": 60,
            "annotations": {
                "horizontal": []
            }
            }
        },

        # Requests por Target Group (Video)
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
            "title": "Requests por Target Group (Video)",
            "region": var.aws_region,
            "metrics": [
                [
                "AWS/ApplicationELB",
                "RequestCountPerTarget",
                "LoadBalancer", aws_lb.main.arn_suffix,
                "TargetGroup", aws_lb_target_group.video.arn_suffix
                ]
            ],
            "stat": "Sum",
            "period": 60,
            "annotations": {
                "horizontal": []
            }
            }
        },

        # Requests totales ALB
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
            "title": "Requests Totales ALB",
            "region": var.aws_region,
            "metrics": [
                [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix ]
            ],
            "stat": "Sum",
            "period": 60,
            "annotations": {
                "horizontal": []
            }
            }
        },

        # Latencia ALB
        {
            "type": "metric",
            "width": 12,
            "height": 6,
            "properties": {
            "title": "Latencia del ALB",
            "region": var.aws_region,
            "metrics": [
                [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix ]
            ],
            "stat": "Average",
            "period": 60,
            "annotations": {
                "horizontal": []
            }
            }
        }

        ]
    })
}
