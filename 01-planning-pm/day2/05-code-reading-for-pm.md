# 05. 개발자와 대화하기 위한 코드 읽기

## 학습 목표

- GitHub PR의 구조와 핵심 정보를 찾는 방법을 안다
- Copilot Chat `/explain`으로 코드를 이해하는 패턴을 익힌다
- OpenAPI/Swagger 명세를 PM 관점에서 읽을 수 있다
- 실제 오픈소스 PR 3개를 Copilot 도움으로 이해한다

**예상 소요**: 50분 (이론 20분 + 실습 30분)

---

## 5.1 PM이 코드를 읽어야 하는 이유

"저는 기획자라서 코드는 몰라도 됩니다."

이 말은 반만 맞습니다. 코드를 **작성할 필요**는 없지만, 코드 변경이 **어떤 기능에 어떤 영향을 주는지** 파악하는 것은 PM의 역할입니다.

코드를 읽지 못할 때 발생하는 문제:

| 상황 | 결과 |
|------|------|
| PR 리뷰 때 개발자 설명만 믿는다 | 기획 의도와 다르게 구현되도 모름 |
| API 명세를 이해 못한다 | 기획서에 잘못된 동작 기술 |
| 에러 로그를 해석 못한다 | 버그 리포트가 불완전해서 재작업 |
| 스프린트 진행 상황을 코드로 못 확인한다 | 회의에서만 의존 |

Copilot이 등장하면서 상황이 바뀌었습니다. 코드를 직접 이해하지 않아도, **Copilot에게 설명을 요청하면** PM 수준의 이해가 가능합니다.

---

## 5.2 GitHub PR 읽는 법

Pull Request(PR)는 개발자가 작성한 코드를 팀에 합치기 위한 제안서입니다. PM이 봐야 하는 부분은 아래 4가지입니다.

### PR 화면 구조

```
GitHub PR 페이지
├── 제목 + 설명 (Description)     ← 1순위로 읽기
├── Files Changed 탭               ← 코드 변경 목록
│   ├── 초록색 줄 (+)  = 추가된 코드
│   └── 빨간색 줄 (-)  = 삭제된 코드
├── Commits 탭                     ← 변경 이력 요약
└── Conversation 탭                ← 리뷰 코멘트 왕래
```

### PM이 PR에서 확인해야 할 것

1. **제목이 기획서의 어떤 스토리/요구사항에 해당하는가?**
2. **어떤 파일들이 변경됐는가?** (범위 파악)
3. **개발자 설명에 "기획서에 없는 변경"이 언급됐는가?**
4. **테스트 코드가 포함됐는가?** (없으면 QA 리스크 있음)

### 코드 변경 이해 — Copilot 활용

PR의 Files Changed에서 diff 텍스트를 복사해서 Chat에 붙이세요:

```
아래 코드 변경 사항(diff)을 PM이 이해할 수 있게 설명해줘.

설명 관점:
1. 어떤 기능이 어떻게 바뀌었는지 (비기술적 언어)
2. 사용자 경험에 어떤 영향을 주는지
3. 기획서에서 확인해야 할 사항이 있는지
4. 잠재적 사이드 이펙트 (다른 기능에 영향 가능성)

[--- diff 붙여넣기 ---]
```

---

## 5.3 실제 diff 예시 읽기

### 예시 1 — 알림 발송 로직 변경

다음은 실제 개발자가 작성할 수 있는 diff입니다. Copilot에게 설명을 요청해보세요.

```diff
// notifications/service.js

- async function sendLearningReminder(userId) {
-   const user = await User.findById(userId);
-   await pushService.send(user.deviceToken, {
-     title: '오늘 학습하셨나요?',
-     body: '목표 달성을 위해 잠깐 기록해보세요!'
-   });
- }

+ async function sendLearningReminder(userId) {
+   const user = await User.findById(userId);
+   const lastRecord = await LearningRecord.findLatest(userId);
+
+   // 오늘 이미 기록한 사용자에게는 알림 발송하지 않음
+   if (lastRecord && isToday(lastRecord.createdAt)) {
+     return;
+   }
+
+   const streak = await StreakService.getCurrent(userId);
+   const message = streak > 7
+     ? `${streak}일 연속 학습 중! 오늘도 기록해보세요 🔥`
+     : '오늘 학습하셨나요? 목표 달성을 위해 잠깐 기록해보세요!';
+
+   await pushService.send(user.deviceToken, {
+     title: '학습 알림',
+     body: message,
+     data: { screen: 'record' }
+   });
+ }
```

이 diff를 Chat에 붙이고 다음 프롬프트로 이해해보세요:

```
위 코드 변경 사항을 PM 관점에서 설명해줘.
기술 용어 없이, 사용자가 경험하는 변화 중심으로.
기획서에서 확인해야 할 부분도 알려줘.
```

**예상 Copilot 설명**:
"기존에는 모든 사용자에게 같은 알림을 보냈는데, 변경 후에는 두 가지가 바뀌었습니다. 첫째, 오늘 이미 학습을 기록한 사용자에게는 알림을 보내지 않습니다. 둘째, 7일 이상 연속 학습 중인 사용자에게는 연속 일수를 포함한 특별 메시지를 보냅니다. 확인 사항: 기획서에 '오늘 기록한 사용자 알림 제외' 케이스가 명시되어 있는지, 7일 기준이 기획 의도와 맞는지 확인이 필요합니다."

---

### 예시 2 — API 응답 구조 변경

```diff
// api/learning/records.js

  router.get('/records/:userId', async (req, res) => {
    const records = await LearningRecord.findByUser(req.params.userId);
-   res.json(records);
+   res.json({
+     data: records,
+     meta: {
+       total: records.length,
+       lastUpdated: new Date().toISOString()
+     }
+   });
  });
```

이 변경은 API 응답 형식이 바뀐 것입니다. 프론트엔드에서 이 API를 사용하던 기존 코드가 영향을 받습니다.

Copilot에게:

```
위 코드 변경이 다른 부분에 영향을 줄 수 있는가? PM 관점에서 확인해야 할 것은?
```

---

## 5.4 API 명세(OpenAPI/Swagger) 읽기

API 명세는 "개발팀이 만든 기능 설명서"입니다. 잘 읽으면 기획서를 더 정확하게 쓸 수 있습니다.

### OpenAPI 명세 구조

```yaml
# 전형적인 OpenAPI 명세 조각
paths:
  /users/{userId}/learning-plan:
    get:
      summary: AI 학습 계획 조회
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: 성공
          content:
            application/json:
              schema:
                type: object
                properties:
                  weeklyGoal:
                    type: integer
                    description: 주간 학습 목표 시간 (분)
                  subjects:
                    type: array
                    items:
                      type: string
                  generatedAt:
                    type: string
                    format: date-time
        '404':
          description: 사용자의 학습 기록이 충분하지 않음
        '429':
          description: AI 분석 요청 한도 초과
```

### API 명세 이해 프롬프트

```
아래 API 명세를 비기술자(PM)가 이해할 수 있도록 설명해줘.

설명해야 할 것:
1. 이 API가 하는 일 (기능 관점, 1~2문장)
2. 파라미터가 의미하는 것 (각 필드 역할 설명)
3. 응답 데이터가 의미하는 것 (각 필드를 사용자 화면 관점으로)
4. 에러 코드별 사용자에게 어떤 메시지를 보여줘야 하는지
5. 기획 시 반드시 고려해야 할 제약 사항

[--- API 명세 붙여넣기 ---]
```

### PM이 API 명세에서 찾아야 할 것

| 항목 | 왜 중요한가 |
|------|------------|
| 에러 코드 (4xx, 5xx) | 각 에러 상황별 사용자 메시지 기획이 필요 |
| 필수 파라미터 | 이 데이터가 없으면 API 호출 불가 → 기획에서 확보 필요 |
| rate limit (429) | 사용자가 너무 빨리 요청하면 기능 막힘 → UX 설계 필요 |
| nullable 필드 | 데이터 없을 때 화면에서 어떻게 처리할지 기획 필요 |
| deprecated 표시 | 곧 사라지는 API → 기획서에서 사용 중이라면 수정 필요 |

---

## 5.5 에러 로그 해석

개발팀에서 에러 로그를 보여주면서 "이 케이스 기획서에 없어요"라고 할 때, Copilot이 도와줍니다.

### 에러 로그 해석 프롬프트

```
아래 에러 로그를 PM이 이해할 수 있도록 분석해줘.

분석 항목:
1. 어떤 종류의 에러인지 (한 줄 요약)
2. 어떤 사용자 행동이 이 에러를 유발했을 가능성이 높은지
3. 사용자 화면에서 어떤 증상으로 나타났을지
4. 기획서에서 이 케이스가 처리되어 있는지 확인 방법
5. 개발팀에게 버그 리포트 전달 시 포함해야 할 정보

[--- 에러 로그 붙여넣기 ---]
```

**예시 에러 로그**:

```
[2026-07-20 14:23:11] ERROR UnhandledPromiseRejection
Error: AI analysis service timeout after 30000ms
  at LearningAnalyzer.analyze (/app/services/ai.js:45:11)
  at LearningPlanController.generate (/app/controllers/plan.js:23:5)
userId: usr_8f3k2m9p
requestId: req_7a1b3c5d
```

이 로그를 Chat에 붙이고 설명을 받으면, PM은 "AI 분석 서비스가 30초 타임아웃되는 케이스"를 이해하고 기획서에 "분석 시간 초과 시 사용자에게 보여줄 메시지"를 추가할 수 있습니다.

---

## 5.6 개발자와 소통하는 PM의 언어

Copilot으로 코드를 이해하고 나면, 개발자에게 더 정확한 질문을 할 수 있습니다.

### 코드 읽기 전후 질문 비교

| 상황 | Before (막연한 질문) | After (정확한 질문) |
|------|-------------------|-------------------|
| PR 리뷰 | "이거 기획대로 됐나요?" | "알림 발송 제외 조건이 '오늘 기록 있음'인데, 자정 기준 or 앱 오픈 기준인지 확인 부탁합니다" |
| API 명세 | "이 API 어떻게 쓰는 건가요?" | "429 에러 시 재시도 가능한 대기 시간이 얼마인지 확인 부탁합니다. 기획서에 포함해야 해서요" |
| 에러 대응 | "이 에러 고쳐주세요" | "AI 타임아웃 에러 케이스에서 사용자에게 어떤 동작이 있어야 하는지 기획서에 추가하려고 합니다. 타임아웃이 발생하는 빈도와 평균 소요 시간을 알 수 있을까요?" |

---

## 실습

### 실습 1. PR diff 이해하기

다음 PR diff를 Copilot Chat에 붙이고 PM 관점 설명을 받으세요.

```diff
// features/onboarding/steps.js

  const ONBOARDING_STEPS = [
    { id: 'welcome', title: '환영합니다' },
    { id: 'goal-setting', title: '목표 설정' },
    { id: 'subject-select', title: '과목 선택' },
+   { id: 'ai-coach-intro', title: 'AI 코치 소개' },
    { id: 'complete', title: '시작하기' },
  ];

- const TOTAL_STEPS = 4;
+ const TOTAL_STEPS = 5;
```

```
위 코드 변경을 PM 관점으로 설명해줘.
사용자가 경험하는 변화는 무엇인가?
기획서에서 확인해야 할 것은 무엇인가?
```

---

### 실습 2. API 명세 읽기

다음 API 명세를 Chat에 붙이고 PM 관점 설명을 받으세요.

```yaml
/ai-coach/recommendations:
  post:
    summary: AI 학습 추천 생성
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required:
              - userId
              - minimumRecords
            properties:
              userId:
                type: string
              minimumRecords:
                type: integer
                default: 7
                description: 분석에 필요한 최소 학습 기록 수
              preferredSubjects:
                type: array
                nullable: true
                items:
                  type: string
    responses:
      '200':
        description: 추천 성공
      '422':
        description: 학습 기록이 minimumRecords 미만
      '503':
        description: AI 분석 서비스 일시 불가
```

설명을 받고 기획서에 추가해야 할 내용을 직접 써보세요:
- 신규 사용자(기록 7개 미만)에게 보여줄 메시지
- AI 서비스 불가 시 사용자에게 보여줄 fallback 화면

---

### 실습 3. 실제 오픈소스 PR 탐색 (선택)

GitHub에서 실제 오픈소스 프로젝트의 최근 PR을 하나 찾아보세요.
(예: [github.com/public-apis/public-apis](https://github.com/public-apis/public-apis) 같은 비개발자도 이해하기 쉬운 저장소)

1. Files Changed 탭에서 변경 내용 복사
2. Copilot Chat에 붙여서 설명 요청
3. "이 PR이 합쳐지면 사용자 경험에 어떤 영향이 있는가?" 추가 질문

---

## 핵심 포인트

1. PM이 코드를 **작성할 필요는 없지만**, PR이 기획 의도대로 구현됐는지 확인하는 것은 PM의 역할입니다
2. Copilot Chat에 diff나 API 명세를 붙이고 "PM 관점으로 설명해줘"만 해도 충분한 이해가 됩니다
3. API 명세에서 **에러 코드 (4xx/5xx)**, **nullable 필드**, **rate limit**는 반드시 기획서에 반영해야 합니다
4. 에러 로그를 이해하면 개발팀에게 더 정확한 질문을 할 수 있고, 버그 수정 속도가 빨라집니다
5. "이 에러 고쳐주세요" → "이 케이스에서 사용자에게 어떤 동작이 필요한지 기획서에 추가하겠습니다"로 소통 방식이 바뀝니다

---

**다음 문서**: [06-meeting-to-jira.md](./06-meeting-to-jira.md) — 회의록 → JIRA/Notion 티켓 자동화
