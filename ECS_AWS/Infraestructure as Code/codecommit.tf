resource "aws_codecommit_repository" "repo" {
  repository_name = "Zemoga-repo"
  description     = "This is the Sample App Repository"
}