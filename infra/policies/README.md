# 팀원 권한 설정

PL은 팀원 사용자·그룹을 만들고 공통 비밀번호 변경·MFA 등록 정책을 연결했습니다. 아래 팀별 파일은 팀원이 직접 AWS 리소스를 만들고 연결할 수 있도록 확대한 권한 초안입니다. 이번 파일 수정으로 AWS 권한이 바뀌지는 않습니다.

## 그룹에 연결할 정책

| 그룹 | 공통 정책 | 팀별 정책 |
| --- | --- | --- |
| `project-scenarios` | `ProjectMemberSelfService` | `ProjectScenarioStarter` |
| `project-detection` | `ProjectMemberSelfService` | `ProjectDetectionStarter` |
| `project-platform` | `ProjectMemberSelfService` | `ProjectPlatformStarter` |

기존 정책 이름을 그대로 사용합니다. 이미 정책을 만들었다면 JSON을 편집하고 새 버전을 기본 버전으로 저장합니다. 그룹 연결은 유지됩니다.

`.template.json` 파일의 가상 계정 번호 **`111122223333`을 프로젝트 계정의 12자리 ID로 모두 교체**한 뒤 AWS 콘솔에 붙입니다. `${aws:username}`과 `${aws:userid}` 같은 정책 변수는 실제 이름으로 바꾸지 않습니다. 현재 리전은 `us-east-1`입니다. 다른 리전에서 작업한다면 ARN과 리전 조건을 함께 수정합니다.

Git에 올리는 템플릿에는 예시 계정 ID를 유지합니다. 실제 계정 ID로 바꾼 정책은 로컬의 `secrets/` 폴더 등에 따로 보관하세요. `.gitignore`는 파일 경로를 제외할 뿐, JSON이나 Markdown 안의 ARN을 자동으로 가리지 않습니다. 커밋 전에 실제 계정 ARN·비밀번호·비밀 키·토큰이 포함됐는지 확인합니다.

## 팀별로 할 수 있는 일

| 파일 | 허용 범위 |
| --- | --- |
| [team1-scenarios.template.json](team1-scenarios.template.json) | 실험용 IAM 사용자·정책 생성, 수정, 삭제, 키 관리, 관리형·인라인 정책 연결과 해제. CloudTrail 이벤트 이력 조회 |
| [team2-detection.template.json](team2-detection.template.json) | 프로젝트 EventBridge 규칙·타깃 연결, Lambda 생성·수정·테스트·삭제, Lambda 로그 관리, DynamoDB 테이블·데이터 관리, 탐지용 IAM 실행 역할·정책 관리 |
| [team3-platform.template.json](team3-platform.template.json) | us-east-1의 EC2 생성·수정·삭제·접속, 보안 그룹·네트워크 관리, 탐지 결과 데이터 읽기·쓰기·삭제, EC2용 IAM 실행 역할·정책·인스턴스 프로파일 관리 |

개발 중 권한 문제로 자주 막히지 않도록 넓게 허용한 정책입니다. 최소권한을 완성한 운영용 정책은 아닙니다.

1팀의 정책 연결은 ReadOnlyAccess로 제한하지 않습니다. 실험용 사용자에 다른 AWS 관리형 정책이나 직접 만든 정책을 연결할 수 있습니다. 이 사용자가 관리자 정책을 받으면, 그 사용자의 키로 계정 전체 작업이 가능해질 수 있습니다. 2·3팀도 자신이 관리하는 실행 역할에 강한 권한을 넣고 Lambda나 EC2를 통해 사용할 수 있습니다. **리소스 이름을 제한했어도 관리자 권한으로의 확대를 완전히 막는 정책은 아닙니다.**

3팀의 `ec2:*`는 us-east-1의 기존 EC2·네트워크에도 적용됩니다. 생성·삭제와 과금이 가능한 범위입니다. 기존 자원을 확인하고 작업하며, 만든 서버와 디스크의 정리 담당자를 기록합니다. S3·CloudTrail 공통 구성은 계속 PL이 관리합니다.

## 리소스 이름 맞추기

이름은 아직 없는 리소스에 대한 제안입니다. 권한 정책은 리소스를 자동으로 만들지 않습니다.

| 대상 | 이름 규칙 |
| --- | --- |
| 1팀 실험용 IAM 사용자·직접 만든 정책 | `iam-threat-monitor-lab-`로 시작 |
| EventBridge 규칙·Lambda 함수 | `iam-threat-monitor-`로 시작 |
| Lambda 로그 그룹 | `/aws/lambda/iam-threat-monitor-`로 시작 |
| DynamoDB 연결 상태 | `iam-threat-monitor-state` |
| DynamoDB 탐지 결과 | `iam-threat-monitor-alerts` |
| 2팀 IAM 역할·직접 만든 역할 정책 | `iam-threat-monitor-detection-`로 시작 |
| 3팀 IAM 역할·직접 만든 역할 정책·인스턴스 프로파일 | `iam-threat-monitor-platform-`로 시작 |

IAM 사용자·역할·정책은 추가 경로 없이 생성하는 것을 기준으로 합니다. 팀원 로그인 이름에는 실험용 `iam-threat-monitor-lab-` 접두사를 쓰지 않습니다. 1팀의 실험용 사용자와 팀원 로그인 사용자는 별개입니다.

2팀의 `iam:PassRole`은 탐지용 역할을 Lambda에 연결할 때만 허용합니다. 3팀은 관제용 역할을 EC2에 연결할 수 있습니다. PassRole은 사람이 실행 역할을 서비스에 전달하는 권한이고, 서비스가 데이터를 읽고 쓰는 권한은 실행 역할에 별도로 넣어야 합니다. [AWS PassRole 안내](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html)

## Lambda와 EC2 실행 역할

- Lambda 역할은 신뢰 정책에서 `lambda.amazonaws.com`을 허용합니다. 필요한 Lambda 로그 기록과 프로젝트 DynamoDB 읽기·쓰기 권한을 연결합니다.
- EC2 역할은 신뢰 정책에서 `ec2.amazonaws.com`을 허용합니다. DynamoDB 결과 읽기 권한을 연결하고, 해당 역할을 인스턴스 프로파일로 EC2에 연결합니다.
- Session Manager 접속을 사용하려면 EC2 역할에 `AmazonSSMManagedInstanceCore`를 연결하고 SSM Agent·네트워크 통신을 준비해야 합니다. 사람에게 접속 권한을 줬다고 서버 접속 준비가 끝나는 것은 아닙니다.
- EC2 Instance Connect를 사용하려면 지원하는 운영체제, 접속 사용자, 해당 방식의 네트워크 조건도 맞아야 합니다. 일반 SSH는 OS 사용자·키·보안 그룹 설정이 별도로 필요합니다.
- 프로젝트 관제는 EC2의 Docker OpenSearch입니다. AWS 관리형 OpenSearch 도메인을 만드는 권한은 포함하지 않았습니다.

EC2 적재 프로그램에는 기본적으로 탐지 결과 읽기 권한을 주면 됩니다. 3팀 사람에게 추가한 데이터 수정 권한을 서버에도 그대로 줄 필요는 없습니다.

## 공통 로그인·MFA 권한

[member-self-service.json](member-self-service.json)은 비밀번호 변경과 본인 MFA 등록을 위한 정책입니다. `${aws:username}`은 그대로 두고, MFA 디바이스 이름은 **`본인사용자이름-phone`**으로 입력합니다. 예: `minsu-phone`.

팀원이 자신의 휴대폰으로 등록한 뒤 로그아웃하고 다시 로그인합니다. QR·인증 코드·설정 키·비밀번호는 공유하지 않습니다. 분실이나 등록 중단으로 생긴 디바이스 문제는 PL이 확인합니다. 이 정책은 모든 AWS 작업에 MFA를 강제하는 정책은 아닙니다.

팀원이 터미널에서 `aws login`을 사용할 때는 해당 그룹에 AWS 관리형 `SignInLocalDevelopmentAccess`도 연결합니다. 이 정책은 로컬 로그인용이며 서비스 작업 권한과 별개입니다. [AWS CLI 로그인 안내](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)

## 콘솔 적용과 확인

1. `wook-admin`으로 IAM → 정책 → 정책 생성 → JSON을 엽니다. 기존 팀별 정책이 있다면 해당 정책을 편집합니다.
2. 가상 계정 ID와 리소스 이름을 맞춘 JSON을 붙입니다. AWS 검증 오류·경고 내용을 확인하고 정책을 생성하거나 기본 버전으로 저장합니다.
3. IAM → 사용자 그룹 → 해당 팀 → 권한 → 정책 연결에서 팀별 정책을 연결합니다.
4. 팀원 계정으로 프로젝트 자원 생성·조회·수정과 실습 후 정리가 되는지 확인합니다. 실제 비밀 키·상태 파일·비밀번호는 저장소에 올리지 않습니다.

이 정책은 기존 사용자·그룹·정책 권한에 더해집니다. PL의 `project-admins`를 팀원 그룹으로 사용하지 않습니다.

공통 Terraform과 팀원이 콘솔에서 만든 리소스가 중복되지 않도록 이름·리전·생성자·관리 방식을 공유합니다. 콘솔 자원을 Terraform으로 옮길 때는 PL이 기존 자원을 가져오거나 정리할 방법을 정합니다.

JSON 문법과 모든 Action 이름을 AWS 공개 정책 생성기 목록과 대조해 확인했습니다. AWS Access Analyzer 검증은 PL CLI 인증 세션 만료로 완료하지 못했습니다. 전체 허용·차단 판단은 인증을 갱신한 뒤 AWS 검증 및 실제 팀원 접근 테스트로 확인해야 합니다. 이번 수정에서 팀별 정책을 AWS에 적용하거나 리소스를 배포하지 않았습니다.

참고: [AWS 자기 MFA 관리 예시](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_mfa-selfmanage.html), [Session Manager 접속 정책](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-quickstart.html), [EC2용 SSM 역할 정책](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonSSMManagedInstanceCore.html)
