
resource "aws_codebuild_project" "build-blue" {
  name          = "${var.app_name}-build-blue"
  description   = "zemoga-app_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.containerAppBuildProjectRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true

  }


  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

  }

  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/Zemoga-repo"
    git_clone_depth = 1
    buildspec = "CI-CD Pipelines/buildspec-blue.yml"

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "refs/heads/main"

  tags = {
    Environment = "${var.app_environment}"
  }
}