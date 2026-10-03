# JSON 필드 참고표

전체 흐름과 예시 읽는 방법은 [samples/README.md](README.md)를 먼저 확인하세요. 아래는 초안의 상세 필드 설명입니다.

## 입력 필드와 팀별 사용

입력의 생산자는 AWS CloudTrail·EventBridge다. 1팀은 행동을 재현하고 실제 로그를 확보·익명화하며, 2팀은 이를 수집하고 Lambda에서 해석한다. 3팀은 AWS 입력 구조를 직접 처리하는 대신 아래 탐지 결과를 소비한다. 입력 샘플은 세 팀의 공통 확인 자료로 사용한다.

아래의 `detail.*`은 EventBridge 안쪽 CloudTrail 기록을 뜻한다. 표의 각 경로는 두 입력에서 공통으로 사용하며, API별 차이는 별도 표에 적었다.

| 필드 | 뜻·자료형 | 생성·주 사용 |
| --- | --- | --- |
| `version` | EventBridge 구조 버전, 문자열 `"0"` | AWS 생성 → 2팀 구조 확인 |
| `id` | EventBridge 이벤트 UUID, 문자열. CloudTrail eventID와 별개 | AWS 생성 → 2팀 전달 추적, 3팀 증거 조회 |
| `detail-type` | 이벤트 종류, `AWS API Call via CloudTrail` | AWS 생성 → 2팀 입력 선별 |
| `source` | 서비스 출처, `aws.iam` | AWS 생성 → 2팀 입력 선별 |
| `account` | 외부 이벤트의 AWS 계정 ID, 12자리 문자열 | AWS 생성 → 2팀 계정 확인 |
| `time` | EventBridge 이벤트 타임스탬프, UTC 문자열. Lambda 수신 시간이 아님 | AWS 생성 → 2팀 전달 추적. 연결 판단에는 사용하지 않음 |
| `region` | EventBridge 이벤트 출처 리전, 문자열 | AWS 생성 → 2팀 수집 확인 |
| `resources` | 관련 ARN 배열. 이 API 호출 샘플에서는 빈 배열 | AWS 생성 → 2팀 참고. 대상 사용자 식별을 이 배열에 의존하지 않음 |
| `detail` | CloudTrail 이벤트 내용, 객체 | AWS 생성 → 2팀 해석 |
| `detail.eventVersion` | CloudTrail 기록 구조 버전, 문자열. 프로젝트 규격 버전과 별개 | AWS 생성 → 2팀 호환성 확인 |
| `detail.eventTime` | API 요청 완료 시각, UTC 문자열. 실제 발생 시간 판단 기준 | AWS 생성 → 2팀 시간 비교, 3팀 근거 시간 표시 |
| `detail.eventSource` | API 서비스, `iam.amazonaws.com` | AWS 생성 → 2팀 선별, 3팀 증거 표시 |
| `detail.eventName` | API 이름, 문자열 | AWS 생성 → 2팀 시나리오 구분, 3팀 증거 표시 |
| `detail.awsRegion` | CloudTrail에 기록된 API 리전, 문자열 | AWS 생성 → 2팀·3팀 근거 표시 |
| `detail.sourceIPAddress` | 요청 출처 IP 또는 서비스 이름, 문자열 | AWS 생성 → 2팀·3팀 근거 표시 |
| `detail.userAgent` | 호출 도구·클라이언트, 문자열 | AWS 생성 → 1팀 재현 확인, 2팀 분석 참고 |
| `detail.requestParameters` | API 요청 인자, 객체 | AWS 생성 → 2팀 대상·정책 추출 |
| `detail.responseElements` | API 응답에 기록된 요소, 객체 또는 null | AWS 생성 → 2팀 결과 확인 |
| `detail.requestID` | 서비스가 만든 요청 ID, 문자열 | AWS 생성 → 1팀·2팀 로그 조사 |
| `detail.eventID` | CloudTrail 이벤트 고유 ID, 문자열 | AWS 생성 → 2팀 중복 제거·alert_id 구성, 3팀 증거 추적 |
| `detail.readOnly` | 읽기 전용 여부, 이 샘플은 false | AWS 생성 → 2팀 이벤트 분류 |
| `detail.eventType` | 기록 유형, 이 샘플은 AwsApiCall | AWS 생성 → 2팀 입력 확인 |
| `detail.managementEvent` | 관리 이벤트 여부, true | AWS 생성 → 2팀 입력 확인 |
| `detail.recipientAccountId` | 이벤트를 수신한 계정 ID, 문자열. 이번 단일 계정 실습의 대상 계정 기준 | AWS 생성 → 2팀 대상 계정 식별, 3팀 대상 표시 |
| `detail.eventCategory` | 이벤트 분류, Management | AWS 생성 → 2팀 입력 확인 |
| `detail.errorCode`, `detail.errorMessage` | 실패 코드·설명, 문자열. 성공 샘플에서는 필드 자체가 없음 | AWS 생성 → 2팀 실패 제외 |

`detail.userIdentity`는 **작업을 실행한 주체**다. 다음 필드들은 AWS가 생성하고 2팀이 결과의 `evidence[].actor`로 옮겨 3팀이 표시한다.

| 작업자 필드 | 뜻 |
| --- | --- |
| `type` | 주체 유형. 샘플은 IAMUser이며 실제 환경에서는 AssumedRole 등이 올 수 있음 |
| `principalId` | 주체 고유 식별자 |
| `arn` | 호출 주체 ARN. 역할 세션이면 역할 세션 ARN을 보존 |
| `accountId` | 작업자 계정 ID. 대상 계정 ID와 구분 |
| `userName` | IAM 사용자 작업자 이름. 역할 세션에는 없을 수 있음 |

대상 사용자를 `userIdentity.userName`으로 해석하지 않는다. API별 대상과 부가 필드는 다음과 같다.

| API·필드 | 뜻·사용 | 생성·사용 팀 |
| --- | --- | --- |
| 두 API의 `detail.requestParameters.userName` | 작업 대상 사용자 이름 | AWS 생성 → 2팀 연결, 3팀 대상 표시 |
| AttachUserPolicy의 `detail.requestParameters.policyArn` | 부착한 관리형 정책 ARN. 문자열 | AWS 생성 → 2팀 증거 생성, 3팀 표시 |
| CreateAccessKey의 `detail.responseElements.accessKey.userName` | 생성된 키의 소유 사용자. 요청 대상과 일치하는지 확인 | AWS 생성 → 2팀 일관성 확인 |
| CreateAccessKey의 `detail.responseElements.accessKey.accessKeyId` | 생성된 키 식별자. 비밀 키가 아님 | AWS 생성 → 2팀·3팀 증거 표시 |
| CreateAccessKey의 `detail.responseElements.accessKey.status` | 생성된 키 상태, Active | AWS 생성 → 2팀·3팀 증거 표시 |
| CreateAccessKey의 `detail.responseElements.accessKey.createDate` | 응답 안의 키 생성 시각 문자열. 표기 형식에 의존하지 않음 | AWS 생성 → 2팀 참고. 연결 시각은 eventTime 사용 |
| AttachUserPolicy의 `detail.responseElements` | 샘플에서는 null. 이것만으로 실패로 판단하지 않음 | AWS 생성 → 2팀 성공 판정 |

필수 연결 정보는 이벤트 ID, eventTime, API 이름·출처, 대상 계정·사용자 이름이다. 모르는 추가 필드는 허용한다. 필수 정보가 없거나 잘못된 경우 성공·대상을 추측해 탐지하지 않고 별도 확인 대상으로 처리하는 것을 제안한다. AWS 입력의 선택 필드는 항상 존재한다고 가정하지 않는다.

## 탐지 결과 필드와 팀별 사용

결과는 **일반 JSON 문서**다. DynamoDB의 `{"S": ...}` 같은 저장 API 표현이나 Lambda 반환용 HTTP 응답 구조가 아니다. 2팀이 생성·보관하고, 3팀 적재 프로그램이 읽어 OpenSearch에 저장한다. PL은 규격을 조율하고, 1팀은 재현 결과와 정상 비교 사례를 확인한다.

| 필드 | 뜻·자료형 | 만드는 팀 → 사용하는 팀 |
| --- | --- | --- |
| `schema_version` | 프로젝트 JSON 규격 버전, `0.1-draft` | PL 합의·2팀 기입 → 3팀 호환성 확인 |
| `alert_id` | 같은 이벤트 쌍에 고정되는 결과 고유 ID, 문자열 | 2팀 → 3팀 OpenSearch 문서 ID·중복 방지 |
| `rule_id` | 탐지 규칙 및 의미 버전 식별자, iam-key-policy-v1 | PL·2팀 합의·2팀 기입 → 1팀·3팀 시나리오 구분 |
| `status` | review_required = 검토 필요. 공격 확정 의미 없음 | 2팀 → 1팀 확인·3팀 표시 |
| `title` | 화면용 짧은 제목, 문자열 | 2팀 → 3팀 표시 |
| `reason` | 대상·시간 차이·두 작업을 설명하는 판단 이유, 문자열 | 2팀 → 1팀 확인·3팀 표시 |
| `target.type` | 대상 유형, IAMUser | 2팀 → 3팀 표시 |
| `target.account_id` | 대상 계정 ID, 문자열 | 2팀 → 1팀 확인·3팀 검색 |
| `target.user_name` | 대상 사용자 이름, 문자열 | 2팀 → 1팀 확인·3팀 검색·표시 |
| `first_event_at` | CreateAccessKey의 eventTime, UTC 문자열 | 2팀 → 3팀 시간 흐름 표시 |
| `last_event_at` | AttachUserPolicy의 eventTime, UTC 문자열 | 2팀 → 3팀 탐지 발생 시간·검색 기준 |
| `detected_at` | 두 이벤트를 확보하여 결과를 최초 생성한 시각, UTC 문자열. 샘플 값은 가상 | 2팀 → 3팀 처리 지연 확인 |
| `correlation.window_seconds` | 규칙의 시간창, 숫자 600 | 2팀 → 1팀 검증·3팀 판단 근거 표시 |
| `correlation.elapsed_seconds` | 두 eventTime 차이, 숫자 300. 정밀도에 따라 소수 허용 | 2팀 → 1팀 검증·3팀 표시 |
| `correlation.match_on` | 연결에 사용한 결과 필드 경로, 문자열 배열 | 2팀 → 3팀 판단 근거 표시 |
| `evidence` | 실제 발생 시간순으로 정렬한 두 근거 이벤트의 발췌 로그, 객체 배열 | 2팀 → 1팀 검증·3팀 시간 흐름 표시 |

`evidence[]`는 원문 전체가 아니라 필요한 필드를 옮긴 발췌 증거다. 원본을 추가 저장하거나 조회할 위치는 아직 정하지 않았다. 아래 모든 필드는 2팀이 생성하고 3팀이 표시·검색하며, 1팀이 실제 로그와 비교한다.

| 근거 필드 | 뜻·입력 출처 |
| --- | --- |
| `event_id` | `detail.eventID`. 원본 조사 및 중복 식별 |
| `eventbridge_id` | 외부 `id`. 전달 추적 |
| `event_name`, `event_source` | `detail.eventName`, `detail.eventSource` |
| `event_time`, `aws_region` | `detail.eventTime`, `detail.awsRegion` |
| `actor.type`, `actor.principal_id` | `detail.userIdentity.type`, `principalId` |
| `actor.account_id`, `actor.arn` | `detail.userIdentity.accountId`, `arn` |
| `actor.user_name` | `detail.userIdentity.userName`. 없으면 null이며 대상 이름으로 대체하지 않음 |
| `source_ip_address` | `detail.sourceIPAddress`. 문자열이며 IP만 온다고 가정하지 않음 |
| `request_parameters.user_name` | `detail.requestParameters.userName` |
| `request_parameters.policy_arn` | AttachUserPolicy의 `policyArn`. CreateAccessKey에는 필드 없음 |
| `response_summary.access_key_id` | CreateAccessKey 응답의 `accessKeyId` |
| `response_summary.access_key_status` | CreateAccessKey 응답의 `status` |
| `response_summary` | CreateAccessKey는 위 두 필드의 객체, AttachUserPolicy는 null |
| `outcome` | 2팀이 판정한 결과, 이번 탐지 증거는 success |
| `error_code`, `error_message` | 입력의 오류 필드. 성공 증거는 null |

탐지 결과의 표에 나온 필드는 필수로 제안한다. 단, `actor.user_name`과 오류 필드는 null을 허용하고 `request_parameters.policy_arn`은 정책 부착 증거에만 존재한다. 주체의 다른 핵심 필드가 없는 실제 로그의 처리 규칙은 추가 로그를 확인해 확정한다. 시각은 UTC ISO 8601 문자열로 보관하고, 계정 ID·각종 ID·버전은 숫자로 변환하지 않는다. 3팀은 시간 필드를 date, 식별자를 keyword로 다루고, evidence의 이벤트별 관계를 유지할 매핑을 검토한다.

## 구조 확인에 사용한 AWS 문서

- [IAM 이벤트의 EventBridge 출처와 CloudTrail detail 구조](https://docs.aws.amazon.com/eventbridge/latest/ref/events-ref-iam.html)
- [EventBridge 외부 메타데이터: id, time, account, resources 등](https://docs.aws.amazon.com/eventbridge/latest/ref/events-structure.html)
- [CloudTrail 필드: eventTime, eventID, 오류와 응답 요소](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html)
- [CloudTrail 작업 주체 userIdentity](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-user-identity.html)
- [CreateAccessKey 요청·응답](https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateAccessKey.html)
- [AttachUserPolicy 요청](https://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachUserPolicy.html)
