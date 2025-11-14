resource "aws_cloudwatch_dashboard" "instances_cpu_dashboard" {
  dashboard_name = "anbapp-instances-cpu"

  dashboard_body = jsonencode({
    widgets = [
      # -------------------------
      #   CPU Web Instance
      # -------------------------
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : "us-east-1",
          "title" : "CPU Usage - Web Instance",
          "period" : 60,
          "stat" : "Average",
          "metrics" : [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.web.id
            ]
          ],
          "annotations" : {}
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
      },

      # -------------------------
      #   CPU NFS Instance
      # -------------------------
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : "us-east-1",
          "title" : "CPU Usage - NFS Instance",
          "period" : 60,
          "stat" : "Average",
          "metrics" : [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.nfs.id
            ]
          ],
          "annotations" : {}
        }
      }
    ]
  })
}