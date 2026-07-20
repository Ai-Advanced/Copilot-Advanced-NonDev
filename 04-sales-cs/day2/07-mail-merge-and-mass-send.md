# 07. 대량 발송 (Mail Merge) — 개인화 + 법적 준수

## 학습 목표

- Gmail + Google Apps Script로 100명 개인화 이메일 발송 워크플로우 구축
- HTML 이메일 템플릿을 Copilot으로 생성하고 변수 치환 구현
- 발송 후 열람/클릭 추적 방법 이해
- 개인정보보호법(국내)과 GDPR(해외)의 핵심 준수 사항 숙지
- 스팸 방지 및 발송 평판 관리 원칙

**예상 소요**: 45분 (실습 포함)

---

## 1부. 대량 발송 전 반드시 알아야 할 것

### 개인정보보호 & 이메일 법규 요약

대량 이메일 발송은 법적 규제가 명확합니다. Copilot이 이메일 초안을 만들어줘도, **법적 준수는 발송자의 책임**입니다.

#### 국내 — 개인정보보호법 + 정보통신망법

```
핵심 의무:
1. 수신자의 사전 동의 (opt-in) 필요
   - B2B 영업 이메일도 "영리 목적" 이면 사전 동의 원칙
   - 예외: 기존 거래관계가 있는 경우 관련 정보 발송 가능
   
2. 수신거부 수단 제공 의무
   - 모든 이메일에 수신거부 링크 또는 방법 명시
   - 수신거부 후 즉시(3일 이내) 처리

3. 발신자 정보 명시
   - 회사명, 연락처, 이메일 주소 반드시 포함

4. 야간 발송 제한 (광고성 이메일)
   - 오후 9시 ~ 오전 8시 광고성 이메일 금지
   - 제목에 "(광고)" 또는 "[광고]" 표시 의무 (광고성인 경우)

위반 시 과태료: 1회 최대 3천만원
```

#### 해외 — GDPR (EU/EEA 수신자)

```
핵심 의무:
1. 명시적 동의 (explicit consent) — 사전 opt-in 필수
   - "연락해도 됩니까?"라는 체크박스 미체크 상태가 기본값이어야 함

2. 처리 목적 고지
   - 이메일 주소를 왜 수집했는지, 어떻게 쓸 건지 명시

3. 삭제 요청 처리 (Right to Erasure)
   - 고객이 데이터 삭제 요청 시 30일 내 처리

4. 데이터 보관 기간 제한
   - 필요 목적이 끝난 데이터는 삭제

위반 시 과징금: 매출의 4% 또는 2,000만 유로 중 높은 금액
```

#### 실전 체크리스트 (발송 전)

```
[ ] 수신자 목록이 opt-in 동의한 연락처인가?
[ ] B2B 이메일이고 업무 관련성이 있는가?
[ ] 이메일에 수신거부 링크가 포함되어 있는가?
[ ] 발신자 정보(회사명, 연락처)가 이메일에 있는가?
[ ] 광고성 이메일이라면 제목에 [광고] 표시했는가?
[ ] 발송 시간이 오전 8시~오후 9시 사이인가?
[ ] 이미 수신거부한 연락처는 목록에서 제거했는가?
[ ] EU/EEA 수신자라면 GDPR 동의 여부 확인했는가?
```

---

## 2부. HTML 이메일 템플릿 만들기

### 왜 HTML 이메일인가?

- 텍스트 이메일보다 **브랜딩, 가독성, CTR(클릭율)**이 높음
- 로고, 버튼, 색상으로 더 전문적으로 보임
- 열람 추적(픽셀 삽입)이 가능

### Gmail/Outlook 호환 HTML 이메일의 제약

HTML 이메일은 일반 웹 HTML과 다릅니다:
- `<div>` 레이아웃이 깨질 수 있어 `<table>` 기반으로 작성
- CSS는 `style=""` 인라인으로만 적용 (외부 CSS 지원 안 함)
- 반응형은 제한적 — 모바일은 별도 `@media` 쿼리 필요
- 일부 이메일 클라이언트에서 JavaScript 비활성화

### Copilot으로 HTML 이메일 생성

**프롬프트**:

```
B2B SaaS 영업용 HTML 이메일 템플릿 작성. Gmail/Outlook 호환.

구조:
1. 헤더: 로고 자리 (alt="회사 로고", src 는 {{logoUrl}})
2. 본문:
   - 인사말: "{{firstName}}님, 안녕하세요."
   - 메인 텍스트: {{bodyText}} 변수 자리
   - 강조 박스: 핵심 혜택 1가지 ({{highlight}} 변수)
3. CTA 버튼: "지금 바로 데모 신청" ({{ctaLink}} 변수, 파란색 배경 #1a73e8)
4. 푸터: 회사명, 주소, 수신거부 링크 ({{unsubscribeLink}})

조건:
- table 기반 레이아웃
- CSS 인라인 스타일만
- 모바일에서도 읽을 수 있는 폰트 크기 (최소 14px)
- 최대 너비 600px
- 배경 흰색, 텍스트 #333333
```

**생성 결과 예시**:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{emailSubject}}</title>
</head>
<body style="margin:0;padding:0;background:#f4f4f4;font-family:Arial,sans-serif;">

  <!-- 외부 래퍼 -->
  <table width="100%" cellpadding="0" cellspacing="0" border="0"
         style="background:#f4f4f4;padding:20px 0;">
    <tr>
      <td align="center">

        <!-- 메인 컨테이너 -->
        <table width="600" cellpadding="0" cellspacing="0" border="0"
               style="background:#ffffff;border-radius:8px;overflow:hidden;
                      max-width:600px;width:100%;">

          <!-- 헤더 -->
          <tr>
            <td style="background:#1a73e8;padding:24px 32px;text-align:center;">
              <img src="{{logoUrl}}" alt="회사 로고" height="40"
                   style="display:block;margin:0 auto;">
            </td>
          </tr>

          <!-- 본문 -->
          <tr>
            <td style="padding:32px;color:#333333;font-size:15px;line-height:1.6;">

              <p style="margin:0 0 16px;">{{firstName}}님, 안녕하세요.</p>

              <p style="margin:0 0 20px;">{{bodyText}}</p>

              <!-- 강조 박스 -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="background:#e8f0fe;border-left:4px solid #1a73e8;
                             padding:16px 20px;border-radius:4px;
                             font-size:14px;color:#1a237e;">
                    <strong>핵심 혜택:</strong> {{highlight}}
                  </td>
                </tr>
              </table>

              <!-- CTA 버튼 -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0"
                     style="margin-top:28px;">
                <tr>
                  <td align="center">
                    <a href="{{ctaLink}}"
                       style="display:inline-block;background:#1a73e8;color:#ffffff;
                              text-decoration:none;padding:14px 32px;border-radius:6px;
                              font-size:15px;font-weight:bold;">
                      지금 바로 데모 신청
                    </a>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- 푸터 -->
          <tr>
            <td style="background:#f8f9fa;padding:20px 32px;font-size:12px;
                       color:#888888;text-align:center;border-top:1px solid #e0e0e0;">
              <p style="margin:0 0 6px;">(주)탠건소프트 | 서울특별시 강남구 테헤란로 123</p>
              <p style="margin:0;">
                문의: <a href="mailto:sales@tangunsoft.com"
                         style="color:#1a73e8;text-decoration:none;">
                  sales@tangunsoft.com
                </a>
                &nbsp;|&nbsp;
                <a href="{{unsubscribeLink}}"
                   style="color:#888888;text-decoration:underline;">
                  수신거부
                </a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
```

---

## 3부. Google Apps Script — 개인화 대량 발송

### 스크립트: 시트 데이터 → 개인화 Gmail 발송

```javascript
// 목적: Google Sheets의 리드 리스트에서 데이터를 읽어
//       각 수신자에게 개인화된 이메일을 Gmail로 발송

function sendPersonalizedEmails() {

  // ===== 설정 변수 (여기만 수정) =====
  const SHEET_NAME   = "Leads";          // 리드 리스트 시트 이름
  const TEMPLATE_SHEET = "EmailTemplate"; // 템플릿 시트 이름
  const SEND_LIMIT   = 50;               // 한 번에 최대 발송 수 (스팸 방지)
  const TEST_MODE    = true;             // true: 본인 이메일로만 발송 (테스트용)
  const TEST_EMAIL   = "yourname@example.com"; // 테스트 수신 이메일
  const LOG_COLUMN   = 15;              // 발송 결과를 기록할 열 번호 (O열)
  // ====================================

  const ss    = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME);
  const data  = sheet.getDataRange().getValues();

  // 템플릿 시트에서 제목과 HTML 본문 읽기
  const tmplSheet = ss.getSheetByName(TEMPLATE_SHEET);
  const subject   = tmplSheet.getRange("B1").getValue(); // B1: 이메일 제목
  const htmlBody  = tmplSheet.getRange("B2").getValue(); // B2: HTML 본문

  let sentCount = 0;

  // 헤더 행(1행) 제외하고 각 리드 처리
  for (let i = 1; i < data.length; i++) {
    if (sentCount >= SEND_LIMIT) break;

    const row = data[i];

    // 이미 발송된 행은 건너뜀 (O열에 "발송완료" 있으면)
    if (row[LOG_COLUMN - 1] === "발송완료") continue;

    // 수신거부 체크 (N열이 "수신거부"면 건너뜀)
    if (row[13] === "수신거부") continue;

    // 데이터 읽기 (열 순서에 맞게 조정)
    const firstName   = row[0];  // A열: 이름
    const company     = row[2];  // C열: 회사
    const email       = row[5];  // F열: 이메일
    const jobTitle    = row[3];  // D열: 직책
    const painPoint   = row[9];  // J열: Pain Point
    const highlight   = row[10]; // K열: 강조 혜택

    if (!email) continue; // 이메일 없으면 건너뜀

    // 변수 치환: {{변수명}} → 실제 값
    let personalizedHtml = htmlBody
      .replace(/{{firstName}}/g, firstName || "고객")
      .replace(/{{company}}/g, company || "귀사")
      .replace(/{{jobTitle}}/g, jobTitle || "")
      .replace(/{{bodyText}}/g, `${company}에서 ${painPoint} 문제를 해결하는 데 도움을 드릴 수 있을 것 같아 연락드렸습니다.`)
      .replace(/{{highlight}}/g, highlight || "데이터 처리 시간 70% 단축")
      .replace(/{{ctaLink}}/g, "https://tangunsoft.com/demo")
      .replace(/{{logoUrl}}/g, "https://tangunsoft.com/logo.png")
      .replace(/{{unsubscribeLink}}/g, `https://tangunsoft.com/unsubscribe?email=${encodeURIComponent(email)}`);

    let personalizedSubject = subject
      .replace(/{{firstName}}/g, firstName || "고객")
      .replace(/{{company}}/g, company || "귀사");

    // 실제 발송 대상 결정 (테스트 모드)
    const recipientEmail = TEST_MODE ? TEST_EMAIL : email;

    try {
      // Gmail 발송
      GmailApp.sendEmail(
        recipientEmail,
        personalizedSubject,
        "이 이메일은 HTML을 지원하는 클라이언트에서 확인해주세요.", // 텍스트 대체
        { htmlBody: personalizedHtml }
      );

      // 발송 로그 기록 (O열)
      sheet.getRange(i + 1, LOG_COLUMN).setValue("발송완료");
      sheet.getRange(i + 1, LOG_COLUMN + 1).setValue(new Date().toLocaleString("ko-KR"));

      sentCount++;
      Utilities.sleep(500); // 0.5초 대기 (스팸 방지, 초당 2건 이하)

    } catch (err) {
      // 오류 기록
      sheet.getRange(i + 1, LOG_COLUMN).setValue("오류: " + err.message);
    }
  }

  // 완료 알림
  SpreadsheetApp.getUi().alert(
    `발송 완료: ${sentCount}건 발송 (${TEST_MODE ? "테스트 모드" : "실제 발송"})`
  );
}
```

### 시트 설정 방법

```
1. 리드 리스트 시트 ("Leads") 준비:
   A열: 이름, B열: 성, C열: 회사, D열: 직책, E열: 업종
   F열: 이메일, G열: 전화, H열: 소스, I열: 상태
   J열: Pain Point, K열: 강조 혜택
   N열: 수신거부 여부 ("수신거부" or 공백)
   O열: 발송 상태 (스크립트가 자동 기록)

2. 템플릿 시트 ("EmailTemplate") 준비:
   B1 셀: 이메일 제목 (예: "{{firstName}}님, {{company}} 데이터 자동화 사례 공유")
   B2 셀: HTML 이메일 본문 전체 (위에서 만든 HTML 코드)
```

---

## 4부. 열람/클릭 추적

### 열람 추적 (1×1 픽셀)

이메일에 1×1 픽셀 투명 이미지를 삽입해서, 이미지를 로드할 때 서버에 열람 기록이 남는 방식입니다.

```html
<!-- HTML 이메일 푸터 위에 추가 -->
<img src="https://your-tracking-server.com/track/open?id={{trackingId}}&email={{emailEncoded}}"
     width="1" height="1" border="0" alt="" style="display:none;">
```

**주의**: 이메일 클라이언트(특히 Apple Mail, Gmail)는 이미지를 프록시 서버를 통해 로드하거나 자동 차단합니다. 열람 추적은 참고 지표로만 활용하세요.

### 클릭 추적 (UTM 파라미터)

링크에 UTM 파라미터를 추가하면 Google Analytics에서 이메일 클릭을 추적할 수 있습니다.

```html
<!-- CTA 버튼 링크에 UTM 추가 -->
<a href="https://tangunsoft.com/demo?utm_source=email&utm_medium=outbound&utm_campaign=q3-coldmail&utm_content={{firstName}}">
  지금 바로 데모 신청
</a>
```

### Copilot으로 UTM 링크 생성

```
프롬프트:
아래 캠페인 정보로 UTM 파라미터가 포함된 링크 5개 생성.

베이스 URL: https://tangunsoft.com/demo
캠페인 정보:
- Source: email
- Medium: outbound
- Campaign: 2026-q3-saas
- Content: 각 이메일 버전별 (cold-v1, cold-v2, followup-1, followup-2, winback)

출력: 각 링크 + 어떤 이메일에서 쓸지 설명 한 줄
```

---

## 5부. 발송 평판 관리

### 스팸으로 분류되지 않으려면

대량 이메일이 스팸으로 처리되면 모든 노력이 무의미합니다.

```
기술적 설정 (IT팀과 함께 확인):
- SPF 레코드 설정 (도메인 인증)
- DKIM 서명 활성화
- DMARC 정책 설정
- Gmail Postmaster Tools로 발송 평판 모니터링

발송 관행:
- 하루 발송 수를 점진적으로 늘리기 (warming up)
  Week 1: 50건/일 → Week 2: 100건/일 → Week 3: 200건/일
- 같은 도메인에서 대량 발송 시 시간 간격 두기 (초당 2건 이하)
- 반송된 이메일(Bounce) 즉시 목록에서 제거
- 수신거부 즉시 처리 (3일 이내)

콘텐츠 관행:
- 스팸 트리거 단어 피하기: "무료", "한정 시간", "지금 바로!", "100% 보장", "!!!", "URGENT"
- 이미지 대 텍스트 비율: 텍스트 60% 이상 유지
- 링크 수: 이메일당 3개 이내
- 제목에 특수문자 과다 사용 금지 (!!!, ???, $$$)
```

---

## 6부. 5가지 Copilot 프롬프트 — Mail Merge 실전

### 프롬프트 1. HTML 이메일 템플릿 + 변수 치환

```
아래 콜드 이메일 텍스트를 HTML 이메일 템플릿으로 변환.
변수는 {{변수명}} 형식 유지.

텍스트 이메일:
[붙여넣기]

HTML 조건:
- 최대 너비 600px, table 기반
- 헤더: 파란색 (#1a73e8) 배경에 로고 자리
- 본문: 14~15px 폰트, #333333 텍스트
- CTA 버튼: 파란색, 텍스트 "데모 신청하기"
- 푸터: 회사 정보 + 수신거부 링크 {{unsubscribeLink}}
- Gmail/Outlook 호환 (inline CSS)

변수 목록도 함께 출력.
```

### 프롬프트 2. Apps Script 변수 치환 함수

```
Google Apps Script에서 이메일 템플릿의 변수를 치환하는 함수 작성.

변수 형식: {{변수명}}
데이터 객체 형태:
{
  firstName: "이민수",
  company: "ABC제조",
  painPoint: "수동 ETL 반복",
  highlight: "70% 공수 절감",
  ctaLink: "https://...",
  unsubscribeLink: "https://..."
}

함수 조건:
- 템플릿 문자열과 데이터 객체를 받아서 치환된 문자열 반환
- 변수가 없는 경우 기본값 처리 (firstName 없으면 "고객")
- 대소문자 무관하게 치환 (예: {{FIRSTNAME}} 도 처리)
- 한국어 주석 포함
```

### 프롬프트 3. 발송 로그 시트 구조 설계

```
이메일 대량 발송 로그를 기록하는 Google Sheets 시트 구조 설계.

기록할 정보:
발송 시각, 수신자 이름, 이메일, 회사, 이메일 유형 (콜드/팔로업/이탈방지),
성공/실패, 오류 메시지 (실패 시), 열람 여부, 클릭 여부

출력:
1. 열 구조 (헤더 목록)
2. Apps Script에서 로그를 기록하는 함수 초안
3. 주간 발송 성과를 계산하는 수식 (발송 수, 성공률, 예상 열람률)
```

### 프롬프트 4. 수신거부 처리 자동화

```
수신거부 처리를 Google Sheets + Apps Script로 자동화하는 방법.

상황:
- 수신거부 링크 클릭 시 Google Forms로 이동
- Forms에서 이메일 주소 수집
- Forms 제출 → Leads 시트에서 해당 이메일의 N열을 "수신거부"로 업데이트

필요한 것:
1. Google Forms 구조 (이메일 필드만)
2. Forms 응답 시트와 Leads 시트를 연결하는 Apps Script
3. 수신거부 후 자동 확인 이메일 발송 스크립트

한국어 주석 포함. 개인정보보호법 준수 주석도 추가.
```

### 프롬프트 5. 발송 시뮬레이션 — 100명 검증

```
100명 대량 발송 전 시뮬레이션 검증 스크립트 작성.

목적: 실제 발송 없이 각 이메일이 올바르게 생성되는지 확인

동작:
1. Leads 시트에서 데이터 읽기
2. 변수 치환 실행
3. 결과를 "SendPreview" 시트에 기록
   - A열: 수신자 이름
   - B열: 이메일 주소
   - C열: 개인화된 제목
   - D열: 본문 앞 200자 (전체 저장 X, 미리보기만)
   - E열: 변수 치환 누락 여부 ("{{" 포함 여부 체크)
4. 치환 누락이 있는 행 강조 표시

Gmail 실제 발송은 없음. 미리보기만.
```

---

## 실습

### 실습 1. HTML 이메일 템플릿 생성

Day 1에서 만든 콜드 이메일 텍스트를 HTML 버전으로 변환해보세요.

```
프롬프트:
아래 콜드 이메일을 HTML 이메일 템플릿으로 변환.
변수: {{firstName}}, {{company}}, {{bodyText}}, {{ctaLink}}, {{unsubscribeLink}}
Gmail/Outlook 호환. 600px. 파란색 CTA 버튼. 수신거부 링크 푸터 포함.
[Day 1에서 만든 콜드 이메일 붙여넣기]
```

### 실습 2. 발송 스크립트 설치 + 테스트

```
Step 1: 새 Google Sheets 생성
Step 2: "Leads" 시트에 샘플 리드 5명 데이터 입력
Step 3: "EmailTemplate" 시트에 제목(B1)과 HTML(B2) 입력
Step 4: Extensions → Apps Script → 위 발송 스크립트 붙여넣기
Step 5: TEST_MODE = true 확인 후 실행
Step 6: 본인 이메일로 테스트 이메일 5통 수신 확인
Step 7: 개인화 변수가 올바르게 치환되었는지 확인
```

### 실습 3. 법적 준수 체크

만들어진 HTML 이메일을 아래 체크리스트로 검토합니다.

```
프롬프트:
아래 이메일을 한국 개인정보보호법/정보통신망법 관점에서 검토해줘.

체크 항목:
1. 수신거부 수단이 있는가?
2. 발신자 정보가 명시되어 있는가 (회사명, 연락처)?
3. 광고성 이메일이라면 제목에 [광고] 표시가 있는가?
4. 야간 발송 문제가 있는 표현이 있는가?
5. 개인정보 수집/이용 동의 관련 이슈가 있는가?

이메일:
[붙여넣기]

문제점이 있으면 구체적인 수정 방법도 제안.
```

---

## 핵심 포인트

1. **개인정보보호법 준수는 선택이 아닌 의무** — 수신거부, 발신자 정보, 동의 확인 반드시
2. **HTML 이메일은 table 기반** — `<div>` 레이아웃은 이메일 클라이언트에서 깨질 수 있음
3. **TEST_MODE 먼저** — 실제 발송 전 반드시 본인 이메일로 테스트해서 변수 치환 확인
4. **하루 발송 한도** — Gmail 개인 계정: 500건/일, Google Workspace: 2,000건/일
5. **열람 추적의 한계** — Apple Mail, Gmail 프록시 때문에 100% 정확하지 않음. 참고 지표로만
6. **반송 + 수신거부는 즉시 처리** — 평판 관리의 핵심

---

**다음 챕터**: [08. 캡스톤: 분기 파이프라인 리부트 →](./08-capstone.md)
