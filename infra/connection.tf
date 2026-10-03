# data는 AWS 리소스를 생성하지 않고 기존 정보를 조회한다.
# 여기서는 Terraform이 사용 중인 로그인 주체를 확인한다.
data "aws_caller_identity" "current" {}

# ARN은 AWS 사용자나 리소스를 식별하는 이름이다.
output "caller_arn" {
  description = "Terraform이 AWS 연결에 사용하는 로그인 주체 ARN"
  value       = data.aws_caller_identity.current.arn

  precondition {
    condition     = !endswith(data.aws_caller_identity.current.arn, ":root")
    error_message = "루트로 연결되어 있습니다. iam-project 프로필을 본인의 IAM 사용자로 다시 로그인하세요."
  }
}
