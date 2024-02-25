# In memory Postgres

For testing inside an EKS cluster that we created from AWS Blueprints (https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/patterns/fargate-serverless), we found that the bundled Postgres Helm chart attempts to create an EBS mount inside a Fargate Container which is not currently supported (https://github.com/aws/containers-roadmap/issues/1113).

We did not want to create an RDS instance for this testing and chose to run an in memory postgres for ephemeral testing.