variable "iam_policies" {
  description = "IAM policies to assign to the principal."
  type        = list(object({
    object_id = string
    role      = string
  }))
}