output "scale_up_policy_arn" {
  description = "The ARN of the autoscaling policy for scaling out based on backlog"
  value       = aws_appautoscaling_policy.scale_up.arn
}

output "scale_in_to_zero_policy_arn" {
  description = "The ARN of the autoscaling policy for scaling in to zero"
  value       = aws_appautoscaling_policy.scale_in_to_zero.arn
}

output "scale_out_cpu_policy_arn" {
  description = "The ARN of the autoscaling policy for scaling out based on CPU utilization"
  value       = aws_appautoscaling_policy.scale_out_cpu.arn
}

output "scale_in_to_zero_based_on_backlog_arn" {
  description = "ARN of the autoscaling policy to scale in to zero for backlog queries when 0 for x minutes"
  value = aws_appautoscaling_policy.scale_in_to_zero_based_on_backlog.arn
}
