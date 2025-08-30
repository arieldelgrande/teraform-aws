resource "aws_ecr_repository" "publish_ecr" {
  name                 = "publish"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}