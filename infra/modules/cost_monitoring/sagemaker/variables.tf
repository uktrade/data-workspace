variable "dashboard_name" {
    description = "Name of the CloudWatch dashboard"
    type = string
}

variable "services_to_monitor" {
    description = "List of AWS services to monitor costs from"
    type = list(string)
    default = ["AmazonSageMaker", "AmazonEC2", "AmazonS3"]
}