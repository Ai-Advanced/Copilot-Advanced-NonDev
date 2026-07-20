# 07. 서베이 자동화 — Google Forms + Apps Script

## 학습 목표

- HR 서베이의 설계 원칙과 문항 유형 이해
- Google Forms + Apps Script로 응답 자동 집계·발송 구현
- 익명성 보장 스크립트 작성
- eNPS / 분기 펄스 서베이 자동화 완성

**예상 소요**: 50분 (실습 포함)

---

## 7.1 HR 서베이 설계 원칙

서베이는 만들기 쉽고 해석하기 어렵습니다. 설계 단계에서 몇 가지 원칙을 지키면 결과의 품질이 훨씬 좋아집니다.

### 원칙 1. 목적 먼저, 문항 나중

서베이를 만들기 전에 "이 결과로 무엇을 결정할 것인가"를 먼저 정의하세요.

| 나쁜 시작 | 좋은 시작 |
|-----------|-----------|
| "직원 만족도 조사를 해봐야겠다" | "번아웃 위험이 높은 팀을 파악해서 관리자 코칭에 우선순위를 정하겠다" |
| "분위기 파악해보자" | "이번 조직 개편 후 심리적 안전감 변화를 측정하겠다" |

### 원칙 2. 짧게 (완료 시간 5분 이내)

응답률과 완료 시간은 반비례합니다. 15분짜리 서베이는 응답률이 40%를 넘기 어렵습니다. 10개 이하 문항, 5분 완료가 기준입니다.

### 원칙 3. 익명성 보장 — 그리고 직원이 믿게 만들기

"익명입니다"라고 써도 직원이 믿지 않으면 의미가 없습니다. 실제로:

- 부서가 5명 미만이면 응답자 식별 가능 → 집계 시 부서 익명화
- Google Forms의 "응답자 이메일 수집" 옵션을 반드시 끄기
- 결과 보고 시 3명 미만 응답 그룹은 표시하지 않음

### 원칙 4. 리커트 척도 일관성

같은 서베이 안에서 척도 방향을 뒤섞지 마세요. "1=매우 불만족, 5=매우 만족"으로 시작했으면 끝까지 동일하게.

### 원칙 5. 서술형은 선택으로

서술형 응답은 정성적 통찰을 주지만 응답 부담을 높입니다. 2~3개 이하, 선택 사항으로 설정하세요.

---

## 7.2 서베이 문항 유형

| 유형 | 용도 | 분석 방법 |
|------|------|-----------|
| 리커트 5점 척도 | 태도·만족도 측정 | 평균, 분포 |
| eNPS (0~10) | 추천 의향 측정 | NPS 공식 |
| 다중 선택 | 원인 파악 | 빈도 집계 |
| 순위 선택 | 우선순위 파악 | 가중 점수 |
| 서술형 (개방형) | 구체적 경험 수집 | 텍스트 분류 |

---

## 7.3 eNPS 측정 설계

### eNPS란

Employee Net Promoter Score. "이 회사를 친구/지인에게 직장으로 추천하시겠습니까?" 0~10점으로 답합니다.

| 구분 | 점수 | 정의 |
|------|------|------|
| Promoter | 9~10 | 적극 추천자 |
| Passive | 7~8 | 수동적 유지 |
| Detractor | 0~6 | 비추천 또는 이탈 위험 |

**계산 공식**: eNPS = (Promoter % - Detractor %)

**해석 기준**:
- -100 ~ 0: 위험
- 0 ~ 20: 평균
- 20 ~ 50: 좋음
- 50 이상: 탁월

### Copilot으로 eNPS 설계

```
eNPS 측정 서베이 문항 설계.

핵심 질문:
- "이 회사를 친구나 지인에게 직장으로 추천하시겠습니까?" (0~10 척도)

후속 질문 5개 (점수 낮은 이유 파악):
1. 낮은 점수(0~6) 응답자용 개방형 1개
2. 전반적 만족 영역 다중 선택 1개 (업무/급여/문화/성장/팀 중 택1)
3. 개선 우선순위 다중 선택 1개
4. 이직 고려 여부 (리커트 5점)
5. 관리자 지원 만족도 (리커트 5점)

익명성 안내 문구 포함.
출력: Markdown.
```

---

## 7.4 분기 펄스 서베이 문항 설계

**Copilot 프롬프트**:
```
분기 펄스 서베이 문항 12개 작성.

측정 영역:
1. eNPS (1개, 0~10 척도)
2. 전반적 몰입도 (2개, 리커트 5점)
3. 관리자 관계 (2개, 리커트 5점)
4. 업무 의미와 성장 (2개, 리커트 5점)
5. 팀 협업과 심리적 안전감 (2개, 리커트 5점)
6. 번아웃 간접 측정 (2개, 리커트 5점)
7. 개선 제안 (1개, 서술형, 선택)

원칙:
- 완료 시간: 5분 이내
- 척도 방향 일관성 (1=전혀 그렇지 않다, 5=매우 그렇다)
- 중립 언어 (관리자 비판 유도하지 않음)
- 익명성 안내 포함

출력: Markdown.
```

---

## 7.5 Google Apps Script로 자동화

Apps Script는 Google Sheets에서 직접 실행되는 JavaScript 기반 스크립트입니다. 코딩을 모르는 HR 담당자도 Copilot이 생성한 스크립트를 붙여넣어 실행할 수 있습니다.

### Apps Script 접근 방법

1. Google Sheets 열기
2. 메뉴: `확장 프로그램` → `Apps Script`
3. 새 스크립트 탭이 열림
4. Copilot이 생성한 코드를 붙여넣고 저장
5. 실행 버튼 클릭 (처음 실행 시 권한 요청 승인)

### 자동화 스크립트 1. 서베이 완료 시 자동 알림

서베이 응답이 들어올 때마다 HR 담당자에게 이메일 알림을 보내는 스크립트입니다.

**Copilot 프롬프트**:
```
Google Apps Script 작성.

목적: Google Forms 응답이 제출될 때마다 HR 담당자에게 이메일 알림

동작:
1. Form 제출 트리거 (onFormSubmit)
2. 제출 시각 + "새 서베이 응답이 접수됐습니다" 메시지
3. 응답 내용은 포함하지 않음 (익명성 보호)
4. 수신자: HR_EMAIL 상수로 정의 (하드코딩 금지)
5. 하루에 최대 1번만 보내기 (중복 알림 방지)

주석: 각 함수에 한국어 설명 포함.
```

**생성된 스크립트 예시**:

```javascript
// 설정 상수 — 실제 이메일로 교체하세요
const HR_EMAIL = "hr@yourcompany.com";
const SURVEY_NAME = "분기 펄스 서베이";

/**
 * Form 제출 시 자동 실행되는 트리거 함수
 * Google Apps Script 트리거 메뉴에서 onFormSubmit에 연결해야 합니다
 */
function onFormSubmit(e) {
  const today = new Date().toDateString();
  const props = PropertiesService.getScriptProperties();
  const lastSentDate = props.getProperty("lastAlertDate");

  // 오늘 이미 보낸 경우 중복 발송 방지
  if (lastSentDate === today) {
    return;
  }

  const timestamp = new Date().toLocaleString("ko-KR");
  const subject = `[${SURVEY_NAME}] 새 응답이 접수됐습니다`;
  const body = `안녕하세요,\n\n${timestamp}에 ${SURVEY_NAME} 응답이 새로 접수됐습니다.\n응답 시트에서 확인해 주세요.\n\n※ 이 알림에는 응답 내용이 포함되지 않습니다 (익명성 보호).`;

  GmailApp.sendEmail(HR_EMAIL, subject, body);

  // 발송 날짜 기록
  props.setProperty("lastAlertDate", today);
}
```

### 자동화 스크립트 2. 응답 자동 집계 및 요약

응답 시트의 리커트 점수를 자동 집계해서 별도 요약 시트에 기록합니다.

**Copilot 프롬프트**:
```
Google Apps Script 작성.

목적: 펄스 서베이 응답 시트의 리커트 점수를 집계해서 요약 시트 업데이트

시트 구조:
- "응답" 시트: A열(타임스탬프), B~K열(각 문항 점수 1~5)
- "요약" 시트: 문항별 평균 점수, 응답 수, 날짜

동작:
1. "응답" 시트의 B~K열 평균 계산
2. 응답 총 수 카운트
3. "요약" 시트의 지정 셀에 업데이트
4. 집계 날짜 기록

주석: 한국어 설명 포함.
실행 방법: 수동 실행 또는 매주 금요일 오후 5시 자동 실행 설정 방법 주석으로 안내.
```

**생성된 스크립트 예시**:

```javascript
/**
 * 펄스 서베이 응답 집계 함수
 * 수동 실행 또는 시간 기반 트리거로 자동화 가능
 *
 * 자동 실행 설정 방법:
 * 1. Apps Script 편집기 좌측 메뉴 → 시계 아이콘 (트리거)
 * 2. 트리거 추가 → 함수: aggregateSurveyResults
 * 3. 이벤트 소스: 시간 기반 → 매주 → 금요일 → 오후 5시
 */
function aggregateSurveyResults() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const responseSheet = ss.getSheetByName("응답");
  const summarySheet = ss.getSheetByName("요약");

  if (!responseSheet || !summarySheet) {
    Logger.log("시트를 찾을 수 없습니다. '응답'과 '요약' 시트 이름을 확인하세요.");
    return;
  }

  const data = responseSheet.getDataRange().getValues();
  // 헤더 제외한 실제 응답 행
  const responses = data.slice(1).filter(row => row[0] !== "");
  const responseCount = responses.length;

  if (responseCount === 0) {
    Logger.log("집계할 응답이 없습니다.");
    return;
  }

  // B~K열 (인덱스 1~10) 평균 계산
  const questionCount = 10;
  const averages = [];

  for (let q = 1; q <= questionCount; q++) {
    const scores = responses
      .map(row => parseFloat(row[q]))
      .filter(score => !isNaN(score) && score >= 1 && score <= 5);

    const avg = scores.length > 0
      ? scores.reduce((a, b) => a + b, 0) / scores.length
      : 0;
    averages.push(Math.round(avg * 100) / 100);
  }

  // 요약 시트에 기록
  const now = new Date().toLocaleString("ko-KR");
  summarySheet.getRange("A1").setValue("마지막 집계");
  summarySheet.getRange("B1").setValue(now);
  summarySheet.getRange("A2").setValue("총 응답 수");
  summarySheet.getRange("B2").setValue(responseCount);

  // 문항별 평균 기록 (A4부터)
  const headers = responseSheet.getRange(1, 2, 1, questionCount).getValues()[0];
  for (let i = 0; i < questionCount; i++) {
    summarySheet.getRange(4 + i, 1).setValue(headers[i] || `문항 ${i + 1}`);
    summarySheet.getRange(4 + i, 2).setValue(averages[i]);
  }

  Logger.log(`집계 완료: ${responseCount}건 응답, ${now}`);
}
```

### 자동화 스크립트 3. 서베이 링크 자동 발송

매 분기 첫 월요일에 서베이 링크를 전 직원에게 자동으로 발송합니다.

**Copilot 프롬프트**:
```
Google Apps Script 작성.

목적: 분기 펄스 서베이 링크를 직원 목록 시트의 이메일로 자동 발송

시트 구조:
- "직원목록" 시트: A열(이름 없이 ID만), B열(이메일), C열(발송여부 Y/N)

동작:
1. "직원목록" 시트에서 C열이 비어있는(미발송) 행만 처리
2. 개인화된 이메일 발송 (이름 없이 익명 처리)
3. 발송 완료 후 C열에 "Y" 기록
4. 발송 실패 시 C열에 "ERROR" 기록 + Logger 기록

이메일 내용:
- 제목: "[GreenTech 분기 서베이] 3분이면 충분합니다"
- 본문: 서베이 목적 + 익명성 보장 안내 + 링크 + 마감일
- SURVEY_URL 상수로 링크 관리
- 실제 이름/ID는 이메일에 포함하지 않음 (익명성)

주석: 한국어 설명.
```

**생성된 스크립트 예시**:

```javascript
// 서베이 설정 — 실제 정보로 교체
const SURVEY_URL = "https://forms.gle/XXXXXXXXXXXXXXXX";
const SURVEY_DEADLINE = "2026년 10월 10일 (금)";
const SENDER_NAME = "GreenTech HR팀";

/**
 * 미발송 직원에게 서베이 링크 발송
 * 직원목록 시트의 C열(발송여부)을 확인하여 미발송자에게만 발송
 */
function sendSurveyEmails() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("직원목록");

  if (!sheet) {
    Logger.log("'직원목록' 시트를 찾을 수 없습니다.");
    return;
  }

  const data = sheet.getDataRange().getValues();
  let sentCount = 0;
  let errorCount = 0;

  // 헤더 제외
  for (let i = 1; i < data.length; i++) {
    const email = data[i][1]; // B열: 이메일
    const isSent = data[i][2]; // C열: 발송여부

    // 이미 발송했거나 이메일이 없으면 건너뜀
    if (isSent === "Y" || !email || email.trim() === "") {
      continue;
    }

    try {
      const subject = "[GreenTech 분기 서베이] 3분이면 충분합니다 🙏";
      const body = `안녕하세요,

GreenTech를 더 좋은 직장으로 만들기 위한 분기 서베이를 시작합니다.
약 3분이면 완료되며, 모든 응답은 익명으로 처리됩니다.

▶ 서베이 참여하기: ${SURVEY_URL}

마감: ${SURVEY_DEADLINE}

여러분의 솔직한 의견이 큰 변화를 만듭니다.
감사합니다.

${SENDER_NAME}
---
※ 이 이메일은 자동 발송됩니다. 문의: hr@greentech.io`;

      GmailApp.sendEmail(email, subject, body);
      sheet.getRange(i + 1, 3).setValue("Y"); // 발송 완료 기록
      sentCount++;

      // API 할당량 초과 방지: 100건마다 1초 대기
      if (sentCount % 100 === 0) {
        Utilities.sleep(1000);
      }
    } catch (err) {
      sheet.getRange(i + 1, 3).setValue("ERROR");
      Logger.log(`발송 실패 (행 ${i + 1}): ${err.message}`);
      errorCount++;
    }
  }

  Logger.log(`발송 완료: ${sentCount}건 성공, ${errorCount}건 실패`);
}
```

---

## 7.6 익명성 보장 체크리스트

서베이 배포 전 이 체크리스트를 반드시 확인하세요.

```markdown
## 서베이 익명성 보장 체크리스트

### 설계 단계
- [ ] Google Forms "응답자 이메일 수집" 옵션 OFF
- [ ] "로그인 필요" 옵션이 익명성을 침해하지 않는지 확인
- [ ] 응답자 식별 가능한 문항 없음 (이름·직원ID 직접 묻지 않음)
- [ ] 팀/부서 인원이 5명 미만인 경우 해당 항목 삭제 또는 병합

### 배포 단계
- [ ] 서베이 링크는 개인화 없이 동일 URL 배포
- [ ] 이메일 본문에 수신자 특정 정보 없음
- [ ] 발송 기록과 응답 기록을 별도 시트로 분리

### 결과 공유 단계
- [ ] 응답 수 3명 미만인 그룹은 결과 미표시
- [ ] 경영진 공유 시 개인별 응답 원본 제공 안 함
- [ ] 자유 서술형 응답에서 식별 가능한 표현 익명화 후 인용
```

---

## 실습 — 분기 펄스 서베이 자동화

### Step 1. 서베이 문항 설계

**Copilot 프롬프트**:
```
GreenTech (B2B SaaS, 60명) 분기 펄스 서베이 문항 10개 작성.

측정:
- eNPS 1개 (0~10)
- 몰입도 2개 (리커트 5점)
- 관리자 지원 2개 (리커트 5점)
- 번아웃 위험 2개 (리커트 5점, 역문항 1개 포함)
- 성장 기회 2개 (리커트 5점)
- 자유 서술 1개 (선택)

척도: 1=전혀 그렇지 않다, 5=매우 그렇다
익명성 안내 문구 첫 페이지에 포함.
출력: Markdown.
```

### Step 2. 자동 집계 스크립트 생성

```
Google Sheets 펄스 서베이 자동 집계 스크립트 작성.

시트:
- "응답": A열(타임스탬프), B~J열(9개 리커트 문항), K열(서술형)
- "요약": 집계 결과 표시

집계 항목:
1. 총 응답 수
2. eNPS 점수 (B열, 0~10 → Promoter/Passive/Detractor 분류)
3. 나머지 8개 문항 평균
4. 역문항 처리 (특정 문항 점수를 6-점수로 변환)
5. 집계 날짜 기록

주석: 한국어 설명 포함. 역문항 처리 방법 설명 포함.
```

### Step 3. 결과 요약 보고서 프롬프트

실제 집계 후 경영진 보고용 요약을 만들 때:

```
아래 펄스 서베이 집계 결과를 경영진 보고용 요약으로 정리.

- 응답률: [XX]%
- eNPS: [XX]점
- 영역별 평균:
  - 몰입도: [X.X]/5
  - 관리자 지원: [X.X]/5
  - 번아웃 위험: [X.X]/5 (높을수록 위험)
  - 성장 기회: [X.X]/5
- 대표 자유 서술 응답 (익명화 필수):
  [응답 3~5개]

보고서 포함 항목:
1. 핵심 수치 요약 (1/2페이지)
2. 전분기 대비 변화
3. 주목할 신호 2~3개
4. 권고 액션 3개 (우선순위 포함)

출력: Markdown.
```

---

## 핵심 포인트

1. **서베이 설계**: 목적 먼저 → 문항 나중. 10개 이하, 5분 이내
2. **eNPS**: (Promoter% - Detractor%) — 20 이상이면 좋은 신호
3. **익명성**: "익명입니다" 말하는 것만큼, 실제로 식별 불가하게 설계하는 것이 중요
4. **Apps Script**: 응답 알림 / 자동 집계 / 자동 발송 — 3가지 핵심 자동화
5. Copilot이 생성한 스크립트는 **샘플 데이터로 먼저 테스트** 후 실 데이터에 적용
6. 3명 미만 그룹의 응답은 결과에서 제외 — 익명성 보호

---

**다음**: [08. 캡스톤 →](./08-capstone.md)
