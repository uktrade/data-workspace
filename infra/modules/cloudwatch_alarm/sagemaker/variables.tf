variable "alarm_name_prefix" {
  type        = string
  description = "The name of the CloudWatch alarm (the endpoint name is added after)"
}

variable "metric_name" {
  type        = string
  description = "The metric to monitor"
}

variable "namespace" {
  type        = string
  description = "The namespace for the metric"
}

variable "period" {
  type        = number
  description = "The namespace for the metric"
}

variable "comparison_operator" {
  type        = string
  description = "Comparison operator for the CloudWatch alarm"
}

variable "threshold" {
  type        = number
  description = "Threshold value for the CloudWatch alarm"
}

variable "evaluation_periods" {
  type        = number
  description = "Number of evaluation periods for the alarm"
}

variable "alarm_actions" {
  type        = list(string)
  description = "Actions to take when alarm is triggered"
}

variable "datapoints_to_alarm" {
  type        = number
  description = "Data points that must be breaching to trigger alarm"

}

variable "alarm_description" {
  type        = string
  description = "Description of the Alarm"
}
