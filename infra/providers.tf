# AWS CLI에서 로그인한 프로필을 사용한다. 인증 정보를 코드에 넣지 않는다.
provider "aws" {
  region  = "us-east-1"
  profile = "iam-project"
}
