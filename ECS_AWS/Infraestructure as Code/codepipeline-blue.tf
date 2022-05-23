resource "aws_codepipeline" "codepipeline-blue" {
  name     = "${var.app_name}-pipeline-blue"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName   = aws_codecommit_repository.repo.repository_name        
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["DefinitionArtifact","ImageArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["ImageArtifact","DefinitionArtifact"]
      version         = "1"

      configuration = {
        ApplicationName = aws_codedeploy_app.deploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.deploy-group.deployment_group_name
        
        TaskDefinitionTemplateArtifact = "DefinitionArtifact"
        TaskDefinitionTemplatePath = "taskdef.json"
        AppSpecTemplateArtifact = "DefinitionArtifact"
        AppSpecTemplatePath = "appspec.yml"
        Image1ContainerName = "IMAGE1_NAME"
      }

    } 
    
  }

    depends_on = [
    aws_codebuild_project.build,
    aws_ecs_cluster.aws-ecs-cluster-zemoga-app,
    aws_ecs_service.aws-ecs-service,
    aws_ecr_repository.aws-ecr,
    aws_codecommit_repository.repo,
    aws_s3_bucket.codepipeline_bucket,
  ]
}


resource "aws_s3_bucket" "codepipeline_bucket-blue" {
  bucket = "${var.app_name}-bucket-blue"
}


resource "aws_iam_role" "codepipeline_role-blue" {
  name = "codepipeline-role-blue"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy-blue" {
  name = "codepipeline_policy-blue"
  role = aws_iam_role.codepipeline_role-blue.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },

    {
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetApplication",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },

            {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },

    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

