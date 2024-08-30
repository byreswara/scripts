variable "iam_policies" {
  description = "IAM policies to assign to the principal."
  type        = list(object({
    object_id = string
    role      = string
  }))
}

variable "iam_scope" {
  description = "IAM scope to assign the policies to."
  type        = string
}