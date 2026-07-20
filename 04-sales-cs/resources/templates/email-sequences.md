# 이메일 시퀀스 템플릿 세트

> 콜드 / 팔로업 / 이탈방지 시퀀스 완성 템플릿.
> `{{변수}}` 부분만 교체하면 즉시 사용 가능합니다.
> Copilot에 붙여넣고 "{{변수}}를 채워줘"라고 요청해도 됩니다.

---

## 시퀀스 A — 콜드 아웃리치 (Day 0 + 팔로업 3단계)

### A-1. Day 0: 첫 콜드 이메일

```
제목 옵션 (아래 중 하나 선택):
A. "{{firstName}}님, {{triggerEvent}}를 보고 연락드렸습니다"
B. "{{industry}} 팀에서 {{painPoint}} 없애는 방법 (3분)"
C. "{{caseCompany}} 사례: {{caseMetric}} — {{company}}에도 가능한지요"

---

{{firstName}}님, 안녕하세요.

{{triggerEvent}}를 보게 됐는데, {{company}}에서도
{{painPoint}} 문제로 고민하고 계신 건 아닐까 싶어 연락드렸습니다.

저희가 비슷한 상황의 {{industry}} 팀들과 작업해보니,
{{caseCompany}}의 경우 {{caseMetric}} 성과를 낸 경험이 있거든요.

15분만 시간 내주시면 {{company}} 상황에 맞는 접근법을 보여드릴 수 있을 것 같습니다.

{{senderName}} / {{senderTitle}}
{{senderEmail}} | {{senderPhone}}
```

**변수 목록**:
- `{{firstName}}` — 수신자 이름
- `{{company}}` — 수신자 회사명
- `{{industry}}` — 업종
- `{{triggerEvent}}` — 연락 계기 (채용공고/기사/이벤트 만남 등)
- `{{painPoint}}` — 핵심 Pain Point
- `{{caseCompany}}` — 비슷한 성공 사례 회사명
- `{{caseMetric}}` — 성과 수치 (예: "ETL 시간 70% 단축")
- `{{senderName}}`, `{{senderTitle}}`, `{{senderEmail}}`, `{{senderPhone}}`

---

### A-2. Day 3: 팔로업 1 — 리마인드 + 새 가치

```
제목:
"{{caseIndustry}} 팀 사례 공유드립니다 ({{firstName}}님 관련)"

---

{{firstName}}님,

지난 주에 연락드렸었는데요.
혹시 도움이 될까 싶어 {{industry}} 업계 팀의 사례 하나를 공유드립니다.

→ {{caseCompany}}: {{caseSituation}} 상황에서 {{productName}} 도입 후 {{caseMetric}}

{{company}} 상황과 비슷하신가요?
관심 있으시면 편하실 때 연락 주세요.

{{senderName}}
```

**추가 변수**:
- `{{caseSituation}}` — 사례 회사의 도입 전 상황
- `{{productName}}` — 우리 제품명

---

### A-3. Day 7: 팔로업 2 — 업종 인사이트 제공

```
제목:
"{{industry}} 데이터 트렌드 — 2026년 주목할 것들"

---

{{firstName}}님,

{{industry}} 담당자분들과 이야기하다 보면 공통적으로 나오는 주제가 있어서요.

최근 제가 주목하는 {{industry}} 데이터 트렌드 2가지를 공유드립니다:

1. {{trend1}} — {{trendExplanation1}}
2. {{trend2}} — {{trendExplanation2}}

이 트렌드가 {{company}}에서도 관련 있는 부분인지 궁금합니다.
짧게 이야기 나눠봐도 좋을 것 같아서요.

{{senderName}}
```

**추가 변수**:
- `{{trend1}}`, `{{trend2}}` — 업종 관련 트렌드
- `{{trendExplanation1}}`, `{{trendExplanation2}}` — 간단 설명

---

### A-4. Day 14: 팔로업 3 — 마지막 시도

```
제목:
"{{firstName}}님께 마지막으로 드리는 메일입니다"

---

{{firstName}}님,

몇 차례 연락드렸는데 답변을 못 받아서, 이걸 마지막 메일로 드리려고 합니다.

지금 관심이 없으시거나 타이밍이 안 맞으신다면 완전히 이해합니다.
나중에 {{painPoint}} 관련 이야기를 나눠볼 기회가 생기신다면 언제든 연락 주세요.

이 이메일에 대한 간단한 피드백도 환영합니다 —
"관심 없음" 한 마디도 괜찮습니다. 그게 저한테는 더 도움이 됩니다.

{{senderName}}
{{senderEmail}}
```

---

## 시퀀스 B — 데모 후 팔로업 (미팅 당일 + 3단계)

### B-1. 미팅 당일: 감사 + 요약

```
제목:
"오늘 미팅 감사드립니다 — 합의 사항 정리"

---

{{firstName}}님,

오늘 {{meetingDuration}} 시간 내주셔서 감사합니다.

**오늘 미팅 요약**:
- {{summaryPoint1}}
- {{summaryPoint2}}
- {{summaryPoint3}}

**{{firstName}}님이 관심 보이신 부분**:
- {{interestPoint1}}
- {{interestPoint2}} (있는 경우)

**다음 단계**:
| 액션 | 담당 | 기한 |
|------|------|------|
| {{action1}} | {{responsible1}} | {{deadline1}} |
| {{action2}} | {{responsible2}} | {{deadline2}} |

{{resourceLinks}} (공유 자료가 있다면)

궁금하신 점 있으시면 언제든 연락 주세요!

{{senderName}} / {{senderTitle}}
```

**변수 목록**:
- `{{meetingDuration}}` — 미팅 길이 (예: "30분")
- `{{summaryPoint1~3}}` — 미팅 핵심 논의 내용
- `{{interestPoint1~2}}` — 고객이 특히 관심 보인 기능/주제
- `{{action1~2}}`, `{{responsible1~2}}`, `{{deadline1~2}}` — 다음 단계 표
- `{{resourceLinks}}` — 공유할 자료 링크 (선택)

---

### B-2. Day 3: 우려사항 대응 + 추가 자료

```
제목:
"{{firstName}}님이 말씀하신 {{concern}} 관련 추가 정보"

---

{{firstName}}님, 안녕하세요.

지난 미팅에서 {{concern}}에 대해 말씀하셨는데,
관련 자료를 찾아봤습니다.

{{concernResponse}}

추가로 {{relatedResource}} (링크/자료)도 도움이 될 것 같아 공유드립니다.

내부 검토하시면서 궁금한 점 생기시면 바로 연락 주세요.

{{senderName}}
```

**추가 변수**:
- `{{concern}}` — 고객이 언급한 우려사항
- `{{concernResponse}}` — 우려사항 대응 내용
- `{{relatedResource}}` — 관련 자료

---

### B-3. Day 7: 결정 지원 + 참고 사례

```
제목:
"내부 검토에 도움이 될 자료 드립니다"

---

{{firstName}}님,

내부 검토 중이신 것 알고, 결정에 도움이 될 자료를 추가로 준비했습니다.

1. {{material1Description}} → {{material1Link}}
2. {{material2Description}} → {{material2Link}}

특히 {{specificContext}}를 고려하시는 분들께 두 번째 자료가 유용하다는 피드백이 있었습니다.

추가 미팅 필요하시면 편하실 때 알려주세요.

{{senderName}}
```

---

### B-4. Day 14: 결정 확인 + 제안 유효기간

```
제목:
"{{firstName}}님, 진행 방향 확인드립니다"

---

{{firstName}}님,

2주 전 미팅 이후 내부 검토가 잘 진행되고 계신지 궁금합니다.

현재 제안서는 {{proposalExpiryDate}}까지 유효하며,
해당 기간 내 계약 시 {{incentive}} 혜택을 드릴 수 있습니다.

진행 여부와 관계없이 현재 상황만 간단히 알려주시면 감사하겠습니다.

{{senderName}}
```

**추가 변수**:
- `{{proposalExpiryDate}}` — 제안서 유효기간
- `{{incentive}}` — 혜택 내용 (예: "첫 달 무료", "온보딩 지원 추가")

---

## 시퀀스 C — 이탈방지 (3단계)

### C-1. 1단계: 근황 확인 (이탈 신호 감지 후 즉시)

```
제목:
"{{firstName}}님, 잘 지내고 계신가요?"

---

{{firstName}}님, 안녕하세요.

요즘 바쁘실 것 같아서 안부가 궁금했습니다.

최근 접속이 뜸하셔서 혹시 서비스 이용 중에
막히거나 불편한 부분이 있으신 건 아닌가 걱정이 됐어요.
사용하시다가 기대했던 것과 다른 부분이 있으시다면
꼭 알려주세요 — 직접 도와드리고 싶습니다.

참고로 {{newFeature}} 기능이 지난달 업데이트됐는데,
{{newFeatureContext}} 상황에서 도움이 되신다는 피드백이 있었습니다.

편하실 때 10분만 시간 주시면 현재 상황 들어보고 싶습니다.

{{csmName}} / {{csmTitle}}
{{csmEmail}}
```

**변수 목록**:
- `{{newFeature}}` — 최근 업데이트된 기능
- `{{newFeatureContext}}` — 그 기능이 도움 되는 상황
- `{{csmName}}`, `{{csmTitle}}`, `{{csmEmail}}` — CSM 정보

---

### C-2. 2단계: 10분 콜 제안 (1주 후, 응답 없을 시)

```
제목:
"{{firstName}}님, 10분만 시간 내주실 수 있을까요?"

---

{{firstName}}님,

지난 주에 연락드렸는데 바쁘셨을 것 같아요.

10분만 시간 주시면, 지금 서비스 이용 현황을 함께 살펴보고
실제로 도움이 되는 부분을 찾아드리고 싶습니다.

아래 링크에서 편하신 시간 선택해 주세요:
→ {{calendarLink}}

또는 이 이메일에 편하신 시간대를 알려주셔도 됩니다.

{{csmName}}
```

---

### C-3. 3단계: 마지막 시도 (2주 후)

```
제목:
"{{firstName}}님, 솔직하게 여쭤봐도 될까요?"

---

{{firstName}}님,

몇 번 연락드렸는데 답변을 못 받아서요.

서비스가 기대하셨던 것과 많이 다른 부분이 있으신가요?
솔직한 피드백을 주신다면 저도 배울 수 있고,
가능하다면 개선점을 찾아드리고 싶습니다.

물론 지금 상황에서 서비스 이용이 어려우신 경우도 완전히 이해합니다.
그런 경우라면 말씀만 해주시면 감사하겠습니다.

{{csmName}}
{{csmEmail}} | {{csmPhone}}
```

---

## 시퀀스 D — 갱신/업셀 (2단계)

### D-1. 갱신 60일 전: 성과 공유 + 갱신 제안

```
제목:
"{{firstName}}님, 지난 {{contractPeriod}} 성과를 공유드립니다"

---

{{firstName}}님, 안녕하세요.

계약 갱신일({{renewalDate}})이 두 달 앞으로 다가왔습니다.
그에 앞서 지난 {{contractPeriod}} 동안의 주요 성과를 공유드리고 싶었습니다.

**{{company}} × {{productName}} 성과 요약**:
- {{achievement1}}
- {{achievement2}}
- {{achievement3}}

갱신과 함께 {{renewalBenefit}}도 제공해드릴 수 있습니다.
편하실 때 짧게 대화 나눠보시면 좋겠습니다.

{{csmName}} / {{csmTitle}}
```

**추가 변수**:
- `{{contractPeriod}}` — 계약 기간 (예: "1년")
- `{{renewalDate}}` — 갱신일
- `{{achievement1~3}}` — 실제 사용 성과 수치
- `{{renewalBenefit}}` — 갱신 혜택 (예: "현재 요금 동결")

---

### D-2. 업셀: 현재 사용 현황 기반 업그레이드 제안

```
제목:
"{{firstName}}님, 슬슬 한계에 가까워지고 있는 것 같아서요"

---

{{firstName}}님, 안녕하세요.

최근 사용 현황을 살펴보니 {{currentUsageStat}} 상황이더라고요.
현재 요금제({{currentPlan}}) 한도의 {{usagePercent}}%에 도달했습니다.

이 추세라면 {{estimatedDate}} 즈음에 한도를 넘어설 것 같아서요.
미리 알려드리는 게 좋을 것 같았습니다.

{{upgradePlan}} 요금제로 업그레이드하시면
{{upgradeFeature1}}와 {{upgradeFeature2}}를 추가로 활용하실 수 있고,
한도 걱정 없이 쓰실 수 있습니다.

전환 비용이나 절차 관련해서 궁금하신 점 있으시면 알려주세요.

{{csmName}}
```

---

## 빠른 참조 — 시퀀스 선택 가이드

| 상황 | 사용할 시퀀스 |
|------|--------------|
| 처음 연락하는 신규 리드 | 시퀀스 A (콜드 아웃리치) |
| 데모 미팅 이후 | 시퀀스 B (데모 후 팔로업) |
| 장기 미사용 고객 | 시퀀스 C (이탈방지) |
| 계약 갱신 시기 고객 | 시퀀스 D (갱신) |
| 사용량 급증 고객 | 시퀀스 D-2 (업셀) |

---

## Copilot 활용 팁 — 이 시퀀스 개인화하기

```
Chat 프롬프트:
아래 이메일 시퀀스 템플릿의 {{변수}}를 채워줘.

수신자 정보:
- 이름: 이민수
- 회사: ABC제조 (제조업)
- 직책: IT팀장
- Pain Point: 수동 ETL, 개발팀 리소스 부족
- 트리거: 데이터 엔지니어 채용공고
- 사례: D제조, 60% 공수 절감

[시퀀스 A 붙여넣기]

조건:
- 제조업 용어 사용 (ETL, ERP, SAP 등)
- 판매 압박 없이
- 각 이메일은 이전 이메일과 자연스럽게 이어지도록
```
