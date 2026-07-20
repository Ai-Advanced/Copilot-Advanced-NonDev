# 06. CRM & 엑셀 자동화

## 학습 목표

- CRM 스키마(leads/accounts/opportunities/deals)를 이해하고 Copilot으로 활용하기
- 영업 파이프라인 시트를 Google Sheets/Excel에서 직접 구축
- VLOOKUP/XLOOKUP, SUMIFS, COUNTIFS 등 핵심 수식을 Copilot으로 즉시 생성
- Google Apps Script로 CRM 알림 및 반복 업무 자동화
- 파이프라인 대시보드를 Copilot 없이도 유지할 수 있는 수준 도달

**예상 소요**: 60분 (실습 포함)

---

## 1부. CRM 스키마 이해

### CRM이란?

CRM(Customer Relationship Management)은 고객 정보, 영업 진행 상황, 커뮤니케이션 이력을 한 곳에서 관리하는 시스템입니다. Salesforce, HubSpot, Pipedrive, 국내에서는 Notion DB, Google Sheets CRM도 많이 씁니다.

### 핵심 4개 테이블 (스키마)

Copilot에게 CRM 관련 작업을 요청할 때 이 구조를 프롬프트에 넣으면 훨씬 정확한 결과가 나옵니다.

```
Leads (리드)
  id            - 고유 ID
  first_name    - 이름
  last_name     - 성
  company       - 회사명
  job_title     - 직책
  industry      - 업종
  email         - 이메일
  phone         - 전화번호
  source        - 리드 소스 (웨비나/인바운드/아웃바운드/레퍼럴)
  status        - 상태 (new/contacted/qualified/disqualified)
  created_at    - 생성일
  assigned_to   - 담당 영업 (담당자명)
  pain_point    - Pain Point 메모
  notes         - 기타 메모

Accounts (계정/회사)
  id            - 고유 ID
  company_name  - 회사명
  industry      - 업종
  size          - 규모 (직원 수)
  annual_revenue - 추정 연매출
  region        - 지역
  tier          - 등급 (SMB/Mid/Enterprise)

Opportunities (영업 기회)
  id            - 고유 ID
  lead_id       - 연결된 리드 ID
  account_id    - 연결된 계정 ID
  name          - 딜 이름
  stage         - 단계 (Prospecting/Qualification/Proposal/Negotiation/Won/Lost)
  amount        - 예상 금액
  probability   - 성사 확률 (%)
  close_date    - 예상 클로즈 날짜
  assigned_to   - 담당 영업
  created_at    - 생성일

Deals (클로즈된 거래)
  id            - 고유 ID
  opportunity_id - 연결된 Opportunity ID
  amount        - 실제 계약 금액
  contract_start - 계약 시작일
  contract_end  - 계약 종료일
  plan          - 요금제 (Starter/Growth/Enterprise)
  mrr           - 월 반복 수익
  csm           - 담당 CSM
```

---

## 2부. Google Sheets CRM 파이프라인 시트 구축

### 기본 파이프라인 시트 구조

```
시트 이름: Deals Pipeline
열 구성:
A: 딜 이름
B: 회사
C: 담당자 이름
D: 직책
E: 단계 (Prospecting/Qualification/Proposal/Negotiation/Won/Lost)
F: 금액 (원)
G: 성사 확률 (%)
H: 가중 금액 (F×G)
I: 예상 클로즈 날짜
J: 담당 영업
K: 마지막 연락일
L: 메모
```

### Copilot으로 수식 생성하기

**핵심 원칙**: 함수 이름을 몰라도 됩니다. "이런 걸 하고 싶다"고 말하면 Copilot이 함수와 수식을 알려줍니다.

```
프롬프트 패턴:
"Google Sheets에서 [열 설명]에서 [조건] 인 경우 [계산]을 하는 수식.
현재 시트: [시트명]. 열 구조: A=[설명], B=[설명], ..."
```

---

## 3부. 핵심 수식 10가지

### 수식 1. 단계별 딜 합계 (SUMIF)

```
프롬프트:
Google Sheets에서 E열(단계)이 "Proposal"인 F열(금액)의 합계를 구하는 수식.
결과 셀: Dashboard 시트의 B5.
```

```
=SUMIF(Pipeline!E:E,"Proposal",Pipeline!F:F)
```

### 수식 2. 가중 파이프라인 총액 (SUMPRODUCT)

```
프롬프트:
G열(성사 확률 %)과 F열(금액)을 곱한 합계 (가중 파이프라인).
단계가 "Won"이나 "Lost"인 행은 제외.
```

```
=SUMPRODUCT(
  (Pipeline!E2:E1000<>"Won")*(Pipeline!E2:E1000<>"Lost"),
  Pipeline!F2:F1000,
  Pipeline!G2:G1000
)/100
```

### 수식 3. 담당자별 딜 수 (COUNTIFS)

```
프롬프트:
J열(담당 영업)이 "김민준"이고 E열(단계)이 "Won"이 아닌 딜 수.
```

```
=COUNTIFS(Pipeline!J:J,"김민준",Pipeline!E:E,"<>Won",Pipeline!E:E,"<>Lost")
```

### 수식 4. XLOOKUP — 회사명으로 담당자 찾기

```
프롬프트:
A열에 회사명이 있고, 다른 시트 "Accounts"에 회사명(A열)과 담당자(D열)가 있어.
A2 셀의 회사명으로 담당자를 Accounts 시트에서 찾아오는 수식.
없으면 "미배정" 표시.
```

```
=XLOOKUP(A2,Accounts!A:A,Accounts!D:D,"미배정")
```

### 수식 5. 이번 달 클로즈 예정 딜 (SUMIFS + DATE)

```
프롬프트:
I열(예상 클로즈 날짜)이 이번 달 범위이고 E열이 "Won"이나 "Lost"가 아닌
F열(금액) 합계. Excel/Google Sheets 양쪽 호환.
```

```
=SUMIFS(
  Pipeline!F:F,
  Pipeline!I:I,">="&DATE(YEAR(TODAY()),MONTH(TODAY()),1),
  Pipeline!I:I,"<="&EOMONTH(TODAY(),0),
  Pipeline!E:E,"<>Won",
  Pipeline!E:E,"<>Lost"
)
```

### 수식 6. 마지막 연락일 기준 "연락 필요" 표시

```
프롬프트:
K열(마지막 연락일)과 오늘의 차이가 7일 이상이고
E열(단계)이 Won/Lost가 아니면 "연락 필요" 표시하는 수식.
조건 미달이면 공백.
```

```
=IF(AND(TODAY()-K2>=7,E2<>"Won",E2<>"Lost"),"⚠️ 연락 필요","")
```

### 수식 7. 단계별 전환율 (전 단계 대비 %)

```
프롬프트:
각 단계별 딜 수를 구하고, 이전 단계 대비 전환율을 계산하는 방법.
단계 순서: Prospecting → Qualification → Proposal → Negotiation → Won

각 단계 딜 수는 COUNTIF로.
전환율 = 현재 단계 수 / 이전 단계 수 × 100
```

```
// 단계별 수 예시 (각 셀에)
Prospecting: =COUNTIF(Pipeline!E:E,"Prospecting")
Qualification: =COUNTIF(Pipeline!E:E,"Qualification")
...

// 전환율 (Qualification/Prospecting)
=IFERROR(B3/B2*100,0)&"%"
```

### 수식 8. 리드 소스별 성과 분석

```
프롬프트:
Leads 시트에서 source별 리드 수와 status가 "qualified"인 수를
각각 집계하는 COUNTIFS 2개. 소스: 웨비나/인바운드/아웃바운드/레퍼럴.
```

```
// 소스별 전체 리드
=COUNTIF(Leads!G:G,"웨비나")

// 소스별 qualified 리드
=COUNTIFS(Leads!G:G,"웨비나",Leads!J:J,"qualified")

// 전환율
=IFERROR(D2/C2,0)  // qualified 수 / 전체 수
```

### 수식 9. 조건부 서식 — 파이프라인 단계별 색상

```
프롬프트:
E열(단계)에 따라 행 전체 색상을 바꾸는 조건부 서식 규칙.
Prospecting: 회색
Qualification: 파란색
Proposal: 노란색
Negotiation: 주황색
Won: 초록색
Lost: 빨간색

Google Sheets 조건부 서식 수식으로 작성.
```

각 단계별 적용 수식:
```
=$E2="Prospecting"   → 배경 회색 (#f5f5f5)
=$E2="Qualification" → 배경 파란색 (#e3f2fd)
=$E2="Proposal"      → 배경 노란색 (#fff9c4)
=$E2="Negotiation"   → 배경 주황색 (#fff3e0)
=$E2="Won"           → 배경 초록색 (#e8f5e9)
=$E2="Lost"          → 배경 빨간색 (#ffebee)
```

### 수식 10. 드롭다운 유효성 검사 + VLOOKUP 자동 채우기

```
프롬프트:
E열에 단계 드롭다운 설정하는 방법 (Google Sheets 데이터 유효성 검사).
드롭다운 목록: Prospecting, Qualification, Proposal, Negotiation, Won, Lost

그리고 A열(딜 이름)을 입력하면 별도 "Products" 시트에서
해당 제품의 기본 가격을 자동으로 F열에 채우는 XLOOKUP 수식.
```

---

## 4부. Google Apps Script — CRM 자동화

Apps Script는 Google Sheets 안에서 실행되는 JavaScript입니다. 개발자가 아니어도 Copilot으로 작성할 수 있습니다.

### 스크립트 1. 리드 상태 변경 알림

```javascript
// Copilot 프롬프트로 생성한 스크립트
// 목적: Leads 시트에서 status 열(J열) 값이 변경될 때 담당자에게 Gmail 알림 발송

function onEdit(e) {
  const sheet = e.source.getActiveSheet();
  
  // "Leads" 시트에서 J열(10번째 열)이 변경될 때만 실행
  if (sheet.getName() !== "Leads" || e.range.getColumn() !== 10) return;
  
  const row = e.range.getRow();
  if (row <= 1) return; // 헤더 행 제외
  
  // 셀 데이터 읽기
  const leadName = sheet.getRange(row, 1).getValue();   // A열: 이름
  const company  = sheet.getRange(row, 3).getValue();   // C열: 회사
  const newStatus = e.value;                            // 변경된 상태
  const oldStatus = e.oldValue || "없음";               // 이전 상태
  const assignee  = sheet.getRange(row, 11).getValue(); // K열: 담당자 이메일
  
  // "Qualified"로 변경 시 팀장에게도 CC
  const managerEmail = "manager@tangunsoft.com"; // ← 여기에 팀장 이메일 입력
  
  if (!assignee) return; // 담당자 없으면 스킵
  
  // 이메일 제목/본문
  const subject = `[리드 업데이트] ${leadName} @ ${company} → ${newStatus}`;
  const body = `
리드 상태가 변경되었습니다.

리드명: ${leadName}
회사: ${company}
변경 전 상태: ${oldStatus}
변경 후 상태: ${newStatus}
변경 시각: ${new Date().toLocaleString("ko-KR")}

시트 확인: ${SpreadsheetApp.getActiveSpreadsheet().getUrl()}
  `.trim();
  
  // 이메일 발송
  const options = {};
  if (newStatus === "qualified") {
    options.cc = managerEmail; // Qualified 시 팀장 CC
  }
  
  GmailApp.sendEmail(assignee, subject, body, options);
}
```

### 스크립트 2. 주간 파이프라인 요약 이메일 자동 발송

```javascript
// 목적: 매주 월요일 오전 9시, 파이프라인 요약을 팀장 이메일로 자동 발송
// 트리거 설정: Apps Script → 트리거 → 시간 기반 → 매주 월요일 9시

function sendWeeklyPipelineSummary() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Deals Pipeline");
  const data = sheet.getDataRange().getValues();
  
  // 설정 변수 (여기만 수정)
  const RECIPIENT = "team-manager@tangunsoft.com";
  const STAGES = ["Prospecting", "Qualification", "Proposal", "Negotiation"];
  
  // 단계별 집계
  let stageSummary = {};
  let totalAmount = 0;
  let weightedAmount = 0;
  
  STAGES.forEach(stage => stageSummary[stage] = { count: 0, amount: 0 });
  
  // 헤더 제외하고 데이터 순회 (2행부터)
  for (let i = 1; i < data.length; i++) {
    const stage = data[i][4];  // E열: 단계
    const amount = data[i][5]; // F열: 금액
    const prob   = data[i][6]; // G열: 확률
    
    if (STAGES.includes(stage)) {
      stageSummary[stage].count++;
      stageSummary[stage].amount += amount;
      totalAmount += amount;
      weightedAmount += amount * (prob / 100);
    }
  }
  
  // 이메일 본문 구성
  let body = `📊 주간 파이프라인 요약 (${new Date().toLocaleDateString("ko-KR")})\n\n`;
  
  STAGES.forEach(stage => {
    const s = stageSummary[stage];
    body += `${stage}: ${s.count}건 / ${s.amount.toLocaleString()}원\n`;
  });
  
  body += `\n총 파이프라인: ${totalAmount.toLocaleString()}원`;
  body += `\n가중 파이프라인: ${Math.round(weightedAmount).toLocaleString()}원`;
  body += `\n\n시트: ${ss.getUrl()}`;
  
  GmailApp.sendEmail(RECIPIENT, `[주간] 파이프라인 요약 ${new Date().toLocaleDateString("ko-KR")}`, body);
}
```

### 스크립트 3. 장기 미연락 리드 알림

```javascript
// 목적: 마지막 연락일이 7일 이상인 활성 딜을 찾아 담당자에게 알림
// 트리거: 매일 오전 9시

function alertStaledDeals() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Deals Pipeline");
  const data = sheet.getDataRange().getValues();
  const today = new Date();
  
  let alertMessage = "📋 연락이 필요한 딜 목록\n\n";
  let hasAlert = false;
  
  // 알림 수신자 설정
  const ALERT_EMAIL = "sales@tangunsoft.com";
  
  for (let i = 1; i < data.length; i++) {
    const stage = data[i][4];       // E열
    const lastContact = data[i][10]; // K열: 마지막 연락일
    const dealName = data[i][0];     // A열
    const company = data[i][1];      // B열
    
    // 클로즈된 딜 제외
    if (stage === "Won" || stage === "Lost") continue;
    if (!lastContact) continue;
    
    const daysSince = Math.floor((today - new Date(lastContact)) / (1000 * 60 * 60 * 24));
    
    if (daysSince >= 7) {
      alertMessage += `⚠️ ${dealName} (${company}) — ${daysSince}일 미연락\n`;
      hasAlert = true;
    }
  }
  
  if (hasAlert) {
    GmailApp.sendEmail(
      ALERT_EMAIL,
      `[알림] 연락 필요한 딜 ${today.toLocaleDateString("ko-KR")}`,
      alertMessage
    );
  }
}
```

---

## 5부. Copilot으로 Apps Script 요청하는 방법

### 프롬프트 패턴

```
Google Apps Script 작성.

시트 이름: [시트명]
시트 구조: A=[설명], B=[설명], ... (관련 열만)

동작:
1. [트리거 조건] 시 실행
2. [읽어야 할 데이터]
3. [처리 로직]
4. [결과 액션] (이메일/시트 업데이트/로그 등)

추가 조건:
- [조건 1]
- [조건 2]

주석: 한국어로 핵심 로직 설명 포함.
설정 변수 (이메일 주소 등)는 스크립트 상단에 분리.
```

### 5가지 Copilot 프롬프트 — CRM/엑셀 실전

**프롬프트 1. 파이프라인 요약 대시보드 수식 세트**

```
Google Sheets 파이프라인 대시보드 수식 세트 작성.

"Deals Pipeline" 시트 구조:
A=딜명, B=회사, E=단계, F=금액, G=확률%, I=예상클로즈일, J=담당영업

"Dashboard" 시트에 표시할 수식 10개:
1. 전체 활성 딜 수 (Won/Lost 제외)
2. 이번 달 클로즈 예정 금액
3. 가중 파이프라인 총액
4. 단계별 딜 수 (Prospecting/Qualification/Proposal/Negotiation)
5. 담당자별 딜 수 TOP 3 (LARGE 함수 활용)
6. Win Rate (Won / (Won + Lost) × 100)
7. 평균 딜 크기
8. 마지막 연락일 7일 이상인 딜 수
9. 이번 분기 목표 달성률 (목표: Dashboard!B1 셀)
10. 다음 분기 클로즈 예정 가중 금액
```

**프롬프트 2. 리드 소스 효율 분석 수식**

```
Leads 시트에서 소스별 효율을 분석하는 수식 세트.

시트 구조:
Leads: A=이름, B=회사, G=소스, J=상태, K=담당자

필요한 수식:
1. 소스별 전체 리드 수 (4가지 소스: 웨비나/인바운드/아웃바운드/레퍼럴)
2. 소스별 qualified 전환율
3. 이번 달 신규 리드 수 (created_at 기준)
4. 소스별 이번 달 리드 수

결과를 Markdown 표로도 보여줘 (소스 / 전체 / Qualified / 전환율 열).
```

**프롬프트 3. 자동 리드 스코어링 수식**

```
리드 스코어링 수식 작성. 0~100점.

Leads 시트 구조:
C=업종, D=직책, E=회사규모(명), H=소스, K=상태

스코어 기준:
- 업종이 "이커머스" or "제조업": +20점
- 직책에 "팀장" or "CTO" or "팀장" 포함: +25점
- 회사 규모 100명 이상: +20점
- 소스가 "레퍼럴": +20점
- 상태가 "qualified": +15점

위 조건을 IF/IFS + AND/OR 로 조합한 수식.
최대 100점. 결과를 M열에 표시.
```

**프롬프트 4. 거래처 이탈 위험 알림 스크립트**

```
Google Apps Script 작성.
목적: Deals 시트에서 계약 만료일이 60일 이내인 고객 찾아서 CSM에게 알림.

시트: "Active Customers"
구조: A=회사명, B=플랜, C=계약만료일, D=담당CSM이메일, E=ARR

동작:
1. 매일 오전 9시 실행
2. C열(계약만료일) - 오늘 <= 60일인 행 필터
3. D열 CSM에게 이메일 알림
4. 이메일 내용: 고객명, 플랜, 만료일, ARR, 갱신 행동 촉구
5. ARR 500만원 이상이면 팀장 CC (manager@example.com)

주석: 한국어로. 설정 변수 상단 분리.
```

**프롬프트 5. CRM 데이터 정제 수식**

```
CRM 데이터 정제 수식 모음 작성.

문제 데이터 상황:
- A열에 "김민준" / "김 민준" / "김민준 " (공백 포함) 혼재
- B열에 회사명이 "ABC(주)" / "(주)ABC" / "ABC 주식회사" 혼재
- E열에 전화번호가 "010-1234-5678" / "01012345678" / "010 1234 5678" 혼재

각 문제별 수식:
1. A열 공백 제거 + 정제 (TRIM)
2. B열 "(주)" 앞/뒤 통일하는 방법 (SUBSTITUTE)
3. E열 전화번호에서 숫자만 추출해서 재포맷하는 수식 (REGEXREPLACE - Google Sheets)

각 수식 설명과 적용 방법 포함.
```

---

## 실습

### 실습 1. 파이프라인 시트 구축

새 Google Sheets 파일을 만들고, 아래 프롬프트로 초기 구조를 잡아보세요.

```
프롬프트:
Google Sheets 영업 파이프라인 시트의 헤더 행을 설계해줘.

포함할 열:
딜 이름, 회사, 담당자, 단계, 금액, 확률, 가중금액, 예상클로즈일,
담당영업, 마지막연락일, 다음액션, 연락필요여부, 메모

조건:
- 가중금액: F×G 자동 계산
- 연락필요여부: 마지막연락일이 7일 이상이면 "⚠️ 연락 필요"
- 단계 열: 드롭다운 설정 방법도 함께

출력: 열 이름 목록 + 각 수식 + Google Sheets 적용 방법
```

### 실습 2. 수식 5개 직접 구현

위에서 배운 수식 중 5개를 직접 구글 시트에 구현해보세요.

```
체크리스트:
[ ] SUMIF — 단계별 딜 합계
[ ] XLOOKUP — 회사명으로 담당자 찾기
[ ] COUNTIFS — 담당자별 활성 딜 수
[ ] 조건부 서식 — 단계별 색상
[ ] 연락 필요 알림 수식
```

### 실습 3. 리드 알림 스크립트 설치

```
Step 1: 구글 시트에서 Extensions → Apps Script 열기
Step 2: 아래 Copilot 프롬프트로 스크립트 생성

프롬프트:
리드 상태 변경 시 Gmail 알림을 보내는 Google Apps Script 작성.

시트: "Leads"
구조: A=이름, B=회사, J=상태, K=담당자이메일

onEdit 트리거. J열 변경 시 K열 이메일로 알림.
이메일: 리드명, 회사, 이전 상태, 새 상태, 변경 시각, 시트 URL.
상태가 "qualified"면 cc에 manager@example.com 추가.
한국어 주석 포함.

Step 3: 생성된 스크립트를 붙여넣고 저장 (Ctrl+S)
Step 4: 테스트 — 시트에서 J열 값 변경 후 이메일 수신 확인
```

---

## 핵심 포인트

1. **CRM 스키마 4개 테이블** (leads/accounts/opportunities/deals)을 프롬프트에 넣으면 Copilot이 훨씬 정확한 수식/스크립트를 만들어줍니다
2. **함수 이름 몰라도 됩니다** — "이런 계산을 하고 싶다"고 말하면 Copilot이 적합한 함수를 선택
3. **XLOOKUP이 VLOOKUP보다 강력** — 오른쪽 방향만 가능했던 VLOOKUP의 한계 없음
4. **Apps Script의 힘** — 구글 시트를 반자동 CRM으로 만들 수 있음 (코딩 몰라도 Copilot으로 생성)
5. **데이터 정제 먼저** — 수식 아무리 좋아도 더러운 데이터에서는 의미 없음

---

**다음 챕터**: [07. 대량 발송 (Mail Merge) →](./07-mail-merge-and-mass-send.md)
