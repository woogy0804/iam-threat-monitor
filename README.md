# iam-threat-monitor
AWS IAM 관련 이상 행위 흐름을 탐지하는 시스템

**목표**: AWS IAM 이벤트를 연결해 의심스러운 행동 흐름과 근거를 관제 화면에 표시한다.
**첫 시나리오**: 같은 대상 IAM 사용자에 대한 액세스 키 생성 → 권한 정책 부착.
**중간발표**: 실제 AWS 행동이 수집·탐지되어 OpenSearch Dashboards에 표시되는 시연.
**목표 구조**: CloudTrail → EventBridge → Lambda → DynamoDB → 관제 적재 프로그램 → OpenSearch → Dashboards.
**개발 방식**: 샘플 JSON과 로컬 Docker로 먼저 개발하고, 발표 전에 AWS 연결을 검증한다.
**확장 후보**: Slack, GuardDuty 결과 연동, LLM 요약. 기본 흐름 완성 후 검토한다.
