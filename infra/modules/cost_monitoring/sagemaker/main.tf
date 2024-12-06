resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/Billing", "EstimatedCharges", "Currency", "USD" ]
          ],
          "period" : 86400,
          "stat" : "Maximum",
          "region" : "eu-west-2",
          "title" : "Monthly AWS Costs"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 7,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/Billing", "EstimatedCharges", "ServiceName", "SageMaker", "Currency", "USD" ],
            [ "AWS/Billing", "EstimatedCharges", "ServiceName", "EC2-Instances", "Currency", "USD" ],
            [ "AWS/Billing", "EstimatedCharges", "ServiceName", "S3", "Currency", "USD" ]
          ],
          "period" : 86400,
          "stat" : "Maximum",
          "region" : "eu-west-2",
          "title" : "Service-Level Costs (SageMaker, EC2, S3)"
        }
      },
      {
        "type" : "metric",
        "x" : 13,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [ "AWS/Billing", "EstimatedCharges", "Currency", "USD", { "stat": "Average" } ]
          ],
          "period" : 3600,
          "stat" : "Average",
          "region" : "eu-west-2",
          "title" : "Hourly AWS Costs"
        }
      }
    ]
  })
}


