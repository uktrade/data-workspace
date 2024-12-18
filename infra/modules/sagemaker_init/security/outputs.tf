output "security_group_id" {
  description = "ID of the SG for the SageMaker endpoints"
  value       = aws_security_group.notebooks_endpoints.id
}