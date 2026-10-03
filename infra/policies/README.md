# 팀원 권한 설정

AWS에 아직 적용하지 않은 정책 파일이다. 콘솔에서 PL이 검토해 생성하고 팀 그룹에 연결한다. 사용자·그룹을 자동으로 만들거나 권한을 변경하는 Terraform 코드는 이번에 추가하지 않았다.

## 먼저 공통 MFA 등록 권한

`member-self-service.json`을 IAM 정책 생성 화면의 JSON 탭에 붙여 넣는다. 정책 이름은 `ProjectMemberSelfService`로 정하고, 아래 세 그룹에 연결한다.

- `project-scenarios`
- `project-detection`
- `project-platform`

이 정책은 경로 없이 생성한 IAM 사용자를 대상으로 한다. `${aws:username}`은 AWS가 현재 사용자 이름으로 바꾸는 정책 변수다. 실제 이름으로 수정하지 않는다. 계정 부분의 `*`는 AWS 공식 자기 관리 예시와 같은 표현이며 사용자 부분은 본인 이름으로 한정한다.

팀원이 비밀번호를 바꾼 뒤 우측 상단 사용자 메뉴의 보안 자격 증명에서 MFA를 등록한다. 인증 앱의 디바이스 이름은 **본인 IAM 사용자 이름으로 시작하고 `-`를 붙인다.** 예를 들어 사용자가 `minsu`면 `minsu-phone`으로 입력한다. QR·코드·설정 키는 공유하지 않는다. 등록 후 로그아웃하고 본인 MFA로 다시 로그인한다.

등록을 중단한 뒤 디바이스 이름이 충돌하면 PL이 미할당 디바이스를 확인해 정리한다. 이 정책은 다른 사용자의 MFA나 자신의 인증 앱 디바이스 삭제를 허용하지 않는다. 본인 MFA 해제는 MFA로 로그인한 경우에만 허용한다. 분실 시 PL에게 복구를 요청한다.

이것은 **MFA 등록과 자기 관리 권한**이다. 모든 AWS 작업에 MFA를 강제하는 정책은 아니다. CLI 로그인과 강제 MFA 정책의 호환성을 확인하지 않은 채 `Deny` 예시를 붙이지 않는다. 액세스 키 생성·다른 사용자 관리 권한도 포함하지 않는다.

## 팀별 시작 권한

`.template.json` 파일에는 가상 계정 번호 `111122223333`이 들어 있다. **콘솔에 붙이기 전에 이 값만 프로젝트 계정 ID로 모두 교체**한다. 정책 변수 `${aws:username}`은 그대로 둔다. 리소스 이름·실습 정책 범위도 확인하고 생성한다. 아래 이름은 아직 없는 리소스에 대한 제안이며 정책 생성이 리소스를 만들지는 않는다.

| 파일 / 정책 이름 | 연결 그룹 | 허용 범위 |
| --- | --- | --- |
| `team1-scenarios.template.json` / `ProjectScenarioStarter` | `project-scenarios` | 지정 테스트 사용자의 키 관리, ReadOnlyAccess만 부착·해제, us-east-1 CloudTrail 이벤트 이력 조회 |
| `team2-detection.template.json` / `ProjectDetectionStarter` | `project-detection` | 프로젝트 규칙 조회, Lambda 코드 수정·테스트, 로그 조회, 상태·결과 테이블 읽기 |
| `team3-platform.template.json` / `ProjectPlatformStarter` | `project-platform` | 탐지 결과 테이블 읽기. 상태 테이블·결과 수정 권한 없음 |

실제 이름은 다음 제안과 맞추거나 정책을 수정한다.

| 대상 | 이름 제안 |
| --- | --- |
| 테스트 IAM 사용자 | `iam-threat-monitor-lab-target` 등 `iam-threat-monitor-lab-`로 시작 |
| EventBridge 규칙 / Lambda 함수 | `iam-threat-monitor-`로 시작 |
| Lambda 로그 그룹 | `/aws/lambda/iam-threat-monitor-`로 시작 |
| DynamoDB 연결 상태 | `iam-threat-monitor-state` |
| DynamoDB 탐지 결과 | `iam-threat-monitor-alerts` |

실습 사용자와 팀원 로그인 사용자는 별개로 만든다. 팀원 로그인 이름에 실습용 `iam-threat-monitor-lab-` 접두사를 쓰지 않는다. 테스트 사용자는 PL이 직접 만들고, 다른 정책이나 그룹으로 높은 권한을 주지 않는 실험 전용 사용자로 준비한다. 1팀은 새 사용자·정책 생성이나 다른 정책 부착을 할 수 없다. 키 생성 API 응답의 실제 비밀 키는 로그·샘플·채팅에 저장하지 않는다.

2팀은 연결에 필요한 코드·Terraform 변경을 준비하고 PL이 리소스를 생성한다. 이 시작 정책에는 리소스 생성·삭제, EventBridge 규칙 변경, Lambda 역할 변경, IAM PassRole, DynamoDB 데이터 쓰기 권한이 없다. 이후 필요한 작업만 검토해 추가한다. Lambda의 DynamoDB 쓰기는 사람의 정책이 아니라 별도 실행 역할에 부여한다. Lambda 코드를 수정하는 권한은 함수 실행 역할의 권한을 사용할 수 있으므로 PL이 실행 역할도 프로젝트 범위로 제한한다.

3팀은 샘플로 로컬 개발을 먼저 진행한다. 결과 테이블이 준비되면 읽기 정책을 적용한다. EC2 접근과 EC2 적재 프로그램 실행 역할은 서버를 준비할 때 추가한다. 사람의 정책을 Lambda나 EC2에 대신 붙이지 않는다.

팀원이 `aws login`으로 CLI를 사용할 때는 해당 그룹에 AWS 관리형 `SignInLocalDevelopmentAccess` 정책도 연결한다. 이는 로컬 로그인 허용이며 팀별 리소스 권한을 대신하지 않는다. [AWS CLI 로그인 요구 권한](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html)

모든 정책은 기존 권한에 더해진다. 시작 정책을 붙였다고 기존 관리자 권한이 줄어들지는 않는다. PL의 `project-admins`를 팀원에게 추가하지 않는다. 콘솔 목록 조회는 리소스별 제한이 어려워 계정의 다른 항목 이름이 보일 수 있으나, 해당 데이터 접근·수정 권한을 허용한다는 뜻은 아니다. 지정 기능 외 콘솔 화면 일부는 접근 거부가 예상된다.

## 콘솔 적용과 확인

1. `wook-admin`으로 IAM → 정책 → 정책 생성 → JSON을 연다.
2. 준비한 JSON을 붙이고 검증 오류를 해결한다. 정책 이름을 입력해 생성한다.
3. IAM → 사용자 그룹 → 해당 그룹 → 권한 → 권한 추가 → 정책 연결에서 선택한다.
4. 팀원이 다시 로그인해 허용 작업을 확인한다. MFA는 등록 및 재로그인, 1팀은 전용 대상 재현·복구, 2팀은 배포된 함수 테스트·로그 조회, 3팀은 결과 테이블 읽기를 확인한다.
5. 예상 밖의 접근 거부는 오류의 API 이름과 리소스를 기록해 PL에게 전달한다. AdministratorAccess로 일괄 해결하지 않는다.

이 파일은 시작 권한안이다. 실제 AWS 정책 검증과 팀원 접근 테스트를 아직 수행하지 않았다. 리소스 이름과 정책 조건의 일치 여부는 적용 전 확인하고, 필요하면 IAM Access Analyzer 정책 검증·IAM Policy Simulator로 확인한다.

참고: [AWS 자기 MFA 관리 예시](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_mfa-selfmanage.html), [IAM 정책 변수](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html)
