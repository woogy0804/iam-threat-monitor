# 공통 JSON 예시

JSON은 항목 이름과 값으로 데이터를 표현하는 형식입니다. 2팀이 만든 결과를 3팀이 그대로 읽을 수 있도록 같은 필드 이름과 의미를 사용합니다.

현재 파일은 **합성 샘플과 규격 초안**입니다. 실제 AWS 로그가 아니며, 비밀 키·비밀번호·세션 토큰은 들어 있지 않습니다. 계정·사용자·이벤트·키 ID는 가상 값이고 IP는 문서용 주소입니다. 실제 로그를 확보한 뒤 초안과 비교해야 합니다.

## 파일 3개의 관계

| 파일 | 누가 사용하는가 |
| --- | --- |
| [create-access-key.eventbridge.json](create-access-key.eventbridge.json) | 2팀이 읽을 키 생성 입력 |
| [attach-user-policy.eventbridge.json](attach-user-policy.eventbridge.json) | 2팀이 읽을 정책 부착 입력 |
| [iam-key-policy.alert.json](iam-key-policy.alert.json) | 2팀이 만들고 3팀이 읽을 탐지 결과 |

앞의 두 파일은 EventBridge가 전체 이벤트를 변환 없이 Lambda에 전달하는 형태입니다. 바깥쪽은 EventBridge 정보이고, `detail` 안쪽은 CloudTrail 기록입니다. CloudTrail 파일의 `Records` 배열이나 API 호출 응답 자체와는 다릅니다.

입력 필드 이름은 AWS 형식을 유지합니다. 우리가 만드는 결과는 `target.user_name`처럼 밑줄로 단어를 구분합니다. 결과는 일반 JSON이며 DynamoDB 저장 API의 `S`, `N` 같은 자료형 표시를 포함하지 않습니다.

## 예시를 읽는 순서

1. `lab-key-operator`가 `lab-target-user`의 키를 생성합니다.
2. 5분 뒤 `lab-policy-operator`가 같은 대상에게 ReadOnlyAccess 정책을 부착합니다.
3. 두 성공 이벤트를 연결해 `review_required`, 즉 **검토 필요** 결과를 만듭니다.

작업자는 다르지만 대상은 같습니다. 정상적인 계정 설정에서도 이런 흐름이 생길 수 있어 공격으로 확정하지 않습니다.

| 확인할 정보 | 입력에서 읽는 위치 | 결과에서 보는 위치 |
| --- | --- | --- |
| 작업자 | `detail.userIdentity` | 각 `evidence`의 `actor` |
| 대상 계정·사용자 | `detail.recipientAccountId`, `detail.requestParameters.userName` | `target` |
| 작업 이름 | `detail.eventName` | 각 `evidence`의 `event_name` |
| 실제 발생 시간 | `detail.eventTime` | `first_event_at`, `last_event_at`, 각 근거의 `event_time` |
| CloudTrail 이벤트 ID | `detail.eventID` | 각 근거의 `event_id` |
| 부착한 정책 | `detail.requestParameters.policyArn` | 정책 부착 근거의 `request_parameters.policy_arn` |
| 판단 이유 | 2팀이 두 이벤트를 비교해 작성 | `reason`, `correlation` |
| 결과 고유 ID | 2팀이 생성 | `alert_id` |

`detected_at`은 결과를 최초로 만든 시각입니다. 실제 이벤트 발생 시각이나 시간 차이 계산에 대신 사용하지 않습니다. `evidence`는 근거 로그의 필요한 필드를 발췌한 배열이며, 원문 전체는 아닙니다. 전체 필드 뜻과 자료형은 [필드 참고표](FIELDS.md)에 있습니다.

## 개발에 사용할 기준

PL 검토 후 진행하기로 한 기준입니다. 실제 입력과 비교하며 필요한 보완 사항을 기록합니다. 파일의 `schema_version`은 아직 `0.1-draft`입니다.

- 같은 대상 계정과 사용자 이름으로 연결합니다. 작업자가 같을 필요는 없습니다.
- 두 API 모두 성공해야 합니다. AttachUserPolicy의 `responseElements: null`만으로 실패로 판단하지 않습니다.
- 시간 차이는 `detail.eventTime`으로 계산합니다. 키 생성보다 늦고 600초 이하이면 연결하며, 정확히 10분은 포함합니다. 같은 시각은 자동 연결에서 제외합니다.
- 같은 대상 계정과 `detail.eventID`가 다시 오면 중복 이벤트로 처리합니다.
- 정책 부착이 먼저 도착해도 보관한 뒤 실제 시간으로 연결합니다.
- 같은 이벤트 쌍은 같은 `alert_id`를 사용합니다. 3팀은 이를 OpenSearch 문서 ID로 사용합니다.

```text
alert_id = 규칙 ID:대상 계정 ID:키 생성 eventID:정책 부착 eventID
```

입력 대상 이름이 빠졌거나 필수 정보가 잘못됐으면 추측해서 연결하지 않습니다. 키 생성 입력은 응답에 기록된 소유 사용자와 대상이 맞는지도 확인합니다. 입력에 작업자 이름·오류 필드가 없으면 결과에는 null로 표현하는 등 세부 규칙은 필드 참고표를 따릅니다.

## 아직 정할 것

- 지연·역순 입력을 위해 이벤트 상태를 얼마나 오래 보관할지
- 여러 키 생성·정책 부착이 조건을 만족하면 모든 쌍을 만들지, 한 쌍을 고를지
- DynamoDB 결과 저장 키와 3팀의 읽기·재시도 방식
- 실제 로그에서 빠지는 필드, IAM 역할 작업자, 대상 이름 생략을 어디까지 지원할지
- 운영 근거의 키 ID·IP·ARN 보관 범위와 원문 조회 방법

1팀은 재현 로그와 정상 비교 사례를 제공하고, 2팀은 입력 구조를 확인해 결과를 생성합니다. 3팀은 결과 샘플로 화면을 먼저 개발하고, 2팀과 조회 방식이 정해지면 DynamoDB를 연결합니다.
