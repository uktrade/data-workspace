# Autoscaling Target
resource "aws_appautoscaling_target" "sagemaker_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = var.resource_id # e.g., "endpoint/${module.gpt_neo_125_endpoint.endpoint_name}/variant/${module.gpt_neo_125_endpoint.variant_name}"
  scalable_dimension = var.scalable_dimension
  service_namespace  = "sagemaker"
}

# Scale-Up Policy (Triggered by Backlog in the Queue)
resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.resource_id}-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = var.scale_out_cooldown

    # Increase instance count if requests are pending
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.sagemaker_target]
}

# Scale-Out Policy Based on CPU Utilization - maintain CPU util at 70% thus
#  Increase instance count for appropriate numbers accordingly to ensure we do
#  not spill over - continous scaling
resource "aws_appautoscaling_policy" "scale_out_cpu" {
  name               = "${var.resource_id}-scale-out-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "CPUUtilization"
      namespace   = "AWS/SageMaker"
      statistic   = "Average"
      unit        = "Percent"
    }

    target_value       = 70.0
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.sagemaker_target]
}

# Scale-In Policy to Reduce Capacity to Zero
resource "aws_appautoscaling_policy" "scale_in_to_zero" {
  name               = "${var.resource_id}-scale-in-to-zero"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = var.scale_in_to_zero_cooldown

    # Adjust capacity to 0 when underutilization is detected
    step_adjustment {
      metric_interval_lower_bound = 0  # Handles all values from 0% and above
      metric_interval_upper_bound = 5  # Upper bound of 5
      scaling_adjustment          = -1 # Set capacity to zero instances
    }

    # Step adjustment to handle all values above the upper bound (fallback)
    step_adjustment {
      metric_interval_lower_bound = null # Anything below 0
      metric_interval_upper_bound = 0    # Unspecified upper bound to catch all higher values
      scaling_adjustment          = -1   # Set capacity to zero instances
    }

  }

  depends_on = [aws_appautoscaling_target.sagemaker_target]
}

# Scale-In Policy to Reduce Capacity to Zero Based on backlog size
resource "aws_appautoscaling_policy" "scale_in_to_zero_based_on_backlog" {
  name               = "${var.resource_id}-scale-in-zero-backlog"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace


  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"       # Set the capacity exactly to zero
    cooldown        = var.scale_in_cooldown # Cooldown period to avoid frequent actions


    # Step adjustment for when there are zero queries in the backlog
    step_adjustment {
      metric_interval_lower_bound = null # No lower bound (cover everything below 0)
      metric_interval_upper_bound = 0.0  # Exact match for zero backlog size
      scaling_adjustment          = 0    # Set capacity to zero instances
    }
  }


  depends_on = [aws_appautoscaling_target.sagemaker_target]
}
