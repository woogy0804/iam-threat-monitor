# 공통 AWS 인프라

이 폴더는 Terraform으로 AWS 공통 리소스를 관리합니다. Terraform은 필요한 구성을 파일에 적고, 생성·수정할 내용을 확인한 뒤 AWS에 적용하는 도구입니다.

## 현재 배포된 구성

```text
AWS 작업 → CloudTrail → S3 원본 로그 보관
```

CloudTrail 추적 이름은 `iam-threat-monitor`, 리전은 `us-east-1`입니다. IAM을 포함한 글로벌 서비스 이벤트와 이 리전의 쓰기 관리 이벤트를 기록합니다. 첫 시나리오의 두 API만 골라 기록하는 설정은 아니며, 이벤트 선별은 다음 단계의 EventBridge가 담당합니다.

2026년 10월 2일 AWS 조회에서 CloudTrail 기록 시작, S3 공개 접근 차단과 AES256 암호화를 확인했습니다. 그 조회에서는 첫 S3 로그 전달 시각이 아직 없었습니다. 실제 시나리오 로그와 Lambda 수신은 별도로 확인해야 합니다.

Terraform이 관리하는 항목은 5개입니다.

| 항목 | 용도 |
| --- | --- |
| S3 버킷 | CloudTrail 원본 로그 보관 |
| S3 공개 접근 차단 | 로그가 외부에 공개되지 않도록 설정 |
| S3 저장 암호화 | S3 관리 키로 파일 암호화 |
| S3 버킷 정책 | 지정한 CloudTrail 추적의 로그 쓰기 허용 |
| CloudTrail 추적 | AWS 작업 기록 시작 |

EventBridge·Lambda·DynamoDB·EC2는 아직 이 구성에 없습니다.

팀원 로그인·MFA와 팀별 시작 권한은 [권한 설정 안내](policies/README.md)를 참고하세요. 정책 파일은 준비했지만 AWS에는 아직 적용하지 않았습니다.

## 파일 안내

| 파일 | 내용 |
| --- | --- |
| `versions.tf` | Terraform과 AWS provider 버전 범위 |
| `providers.tf` | 리전과 로컬 로그인 프로필 선택 |
| `connection.tf` | 현재 로그인 주체 조회, 루트 연결 시 오류 표시 |
| `cloudtrail.tf` | 위의 CloudTrail·S3 구성 |
| `.terraform.lock.hcl` | 초기화 시 선택된 provider 버전과 검증 해시 |

provider는 Terraform이 AWS와 통신할 때 사용하는 플러그인입니다. `iam-project`는 PL PC에 만든 AWS CLI 로그인 프로필이며, 다른 팀원의 PC에도 자동으로 생기는 설정은 아닙니다.

## 명령어와 배포 방식

공통 AWS 인프라는 현재 **PL이 배포**합니다. 팀원은 코드를 확인하고 필요한 변경을 전달하세요. 같은 구성에 각자 `apply`하면 관리 상태가 나뉠 수 있습니다.

PL이 작업할 때는 PowerShell에서 실행합니다.

```powershell
aws login --profile iam-project
cd C:\iam-threat-monitor\infra
terraform init
terraform validate
terraform plan
```

| 명령 | 하는 일 |
| --- | --- |
| `init` | provider 설치와 작업 폴더 초기화 |
| `validate` | 설정 문법 확인. AWS 권한을 검사하는 명령은 아님 |
| `plan` | AWS에 적용할 생성·변경·삭제 내용 미리 확인 |
| `apply` | 검토한 구성을 AWS에 실제 적용 |

이미 배포된 현재 구성에는 최초의 `5 to add` 안내가 적용되지 않습니다. 설정과 AWS 상태가 같으면 `No changes`가 예상됩니다. 변경 사항이 있으면 내용을 확인한 뒤 적용합니다.

`caller_arn`은 연결한 사용자의 AWS 식별자입니다. PL의 실제 IAM 사용자 이름은 `wook-admin`이며, 문서의 초기 제안 이름과 다를 수 있습니다. 인증 세션이 만료되면 다시 로그인합니다. `login_session`을 지원하지 않는 도구에는 [AWS 공식 credential_process 방식](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)을 사용합니다.

## 상태 파일과 정리

`terraform.tfstate`는 Terraform이 어떤 AWS 리소스를 관리하는지 기록한 파일입니다. 현재 PL PC에 보관하며 **Git에 올리지 않습니다**. 이 파일을 지우거나 팀원 PC에서 새 상태로 같은 리소스를 배포하지 마세요. 공동 배포가 필요해지면 상태 공유 방식을 먼저 정합니다.

`.terraform/`도 Git에서 제외하고 `.terraform.lock.hcl`은 포함합니다. 비밀번호·키·토큰은 Terraform 파일에 넣지 않습니다.

S3 로그 저장과 요청에는 사용량이 발생하므로 남은 크레딧과 예산을 확인합니다. 로그 자동 삭제 기간은 아직 정하지 않았습니다. 버킷은 `force_destroy = false`로 설정해, 로그가 들어 있으면 자동으로 비우고 삭제하지 않습니다. 종료 시 로그 보관과 정리 절차를 따로 결정합니다.

참고: [CloudTrail용 S3 정책](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html), [CloudTrail 이벤트의 EventBridge 전달](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-service-event-cloudtrail.html)
