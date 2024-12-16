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
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ],
          "period" : 86400,
          "stat" : "Maximum",
          "region" : "us-east-1",
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
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonSageMaker", "Currency", "USD"],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD"],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonS3", "Currency", "USD"]
          ],
          "period" : 86400,
          "stat" : "Maximum",
          "region" : "us-east-1",
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
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", { "stat" : "Average" }]
          ],
          "period" : 3600,
          "stat" : "Average",
          "region" : "us-east-1",
          "title" : "Hourly AWS Costs"
        }
      }
    ]
  })
}


