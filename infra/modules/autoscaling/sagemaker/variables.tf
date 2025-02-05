variable "resource_id" {
  type        = string
  description = "The resource ID of the SageMaker endpoint variant for autoscaling"
}

variable "scalable_dimension" {
  type        = string
  description = "The scalable dimension for autoscaling"
}

variable "min_capacity" {
  type        = number
  description = "The minimum capacity for autoscaling"
}

variable "max_capacity" {
  type        = number
  description = "The maximum capacity for autoscaling"
}

variable "scale_in_cooldown" {
  type        = number
  description = "Cooldown period for scaling in"
}

variable "scale_out_cooldown" {
  type        = number
  description = "Cooldown period for scaling out"
}

variable "scale_in_to_zero_cooldown" {
  type        = number
  description = "Cooldown period for scaling in to zero"
}
