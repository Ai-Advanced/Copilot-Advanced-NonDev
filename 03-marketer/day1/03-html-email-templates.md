# 03. HTML 이메일 템플릿 — Gmail·Outlook 호환 제작

## 학습 목표

- HTML 이메일이 일반 웹 HTML과 다른 이유와 table 기반 레이아웃 원칙 이해
- 인라인 CSS, 다크모드 대응, 반응형 처리를 Copilot으로 생성
- Gmail·Outlook 모두에서 깨지지 않는 뉴스레터 템플릿 완성
- 이미지 URL·브랜드 색상만 교체하면 바로 발송 가능한 수준으로 마무리

**예상 소요**: 75~90분

---

## 3.1 HTML 이메일이 까다로운 이유

"그냥 HTML 파일 아닌가요?"라고 생각하면 큰코다칩니다.

이메일 클라이언트(Gmail, Outlook, Apple Mail 등)는 각자 다른 HTML/CSS 엔진을 씁니다. 특히 **Outlook은 Word 렌더링 엔진**을 사용해서, 최신 CSS를 전혀 지원하지 않습니다.

| 지원 안 되는 CSS (Outlook 기준) | 대안 |
|---------------------------------|------|
| `display: flex` | `<table>` 기반 레이아웃 |
| `display: grid` | 중첩 `<table>` |
| `position: absolute/relative` | `<td>` 패딩/마진으로 대체 |
| `background-image` (일부) | `<img>` 태그로 대체 |
| `<link>` 스타일시트 | **인라인 CSS** (style="...") |

**핵심 원칙 3가지**
1. 레이아웃은 `<table>` + `<td>` 로만
2. 스타일은 모두 인라인 CSS (`style=""`)
3. 이미지는 반드시 `width`/`height` 속성 명시

---

## 3.2 HTML 이메일 기본 구조

Copilot에게 이메일 HTML을 요청할 때 이 구조를 기준으로 달라고 하면 결과가 훨씬 깔끔합니다.

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>이메일 제목</title>
  <!--[if mso]>
  <style type="text/css">
    table { border-collapse: collapse; }
  </style>
  <![endif]-->
  <style>
    /* 반응형: 모바일에서 폭 100% */
    @media only screen and (max-width: 600px) {
      .email-container { width: 100% !important; }
      .stack-column { display: block !important; width: 100% !important; }
    }
    /* 다크모드 */
    @media (prefers-color-scheme: dark) {
      .dark-bg { background-color: #1a1a1a !important; }
      .dark-text { color: #ffffff !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f4f4;">
  <!-- 외부 컨테이너 -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
    <tr>
      <td align="center" style="padding: 20px 0;">
        <!-- 이메일 본체: 최대 600px -->
        <table class="email-container" role="presentation" width="600"
               cellpadding="0" cellspacing="0" border="0"
               style="background-color: #ffffff; max-width: 600px;">

          <!-- 여기에 섹션들 추가 -->

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## 3.3 섹션별 Copilot 프롬프트

HTML 이메일 전체를 한 번에 달라고 하면 중간에 내용이 누락될 수 있습니다. **섹션별로 나눠서 요청**한 뒤 조합하는 방식이 더 안정적입니다.

### 섹션 1. 헤더 (로고 + 네비게이션)

```
HTML 이메일 헤더 섹션 작성 (table 기반).

포함 요소:
- 로고 이미지 (최대 200px, alt="[브랜드명]")
- 배경색: #0A2E4A (다크 네이비)
- 로고 좌측 정렬 or 중앙 정렬
- 상하 패딩: 16px

Outlook 호환 (인라인 CSS, table 기반, flex 사용 금지).
```

### 섹션 2. 히어로 배너

```
HTML 이메일 히어로 배너 섹션 작성.

포함 요소:
- 배너 이미지 (600px 너비, 300px 높이, 반응형)
- 이미지 위에 텍스트 오버레이 (Outlook은 오버레이 안 되니까 이미지 아래에 텍스트)
- 메인 헤드라인: "{{headline_text}}" (굵게, 28px)
- 서브 헤드라인: "{{sub_headline}}" (16px, 회색)
- CTA 버튼: "{{cta_text}}" (배경 #E8501A, 흰색 텍스트, 모서리 4px)

Outlook 호환. 인라인 CSS.
```

### 섹션 3. 3컬럼 혜택 섹션

```
HTML 이메일 3컬럼 혜택 섹션 작성 (table 기반).

각 컬럼:
- 아이콘 이미지 (48×48px)
- 제목 (16px, 굵게)
- 설명 (14px, 줄간격 1.5)

데스크톱: 3열 나란히 (각 192px)
모바일: 세로로 쌓이게 (@media 쿼리)
컬럼 간 패딩: 16px

Outlook 호환. 인라인 CSS 위주, @media는 <style> 태그에.
```

### 섹션 4. 제품 소개 (이미지 + 텍스트)

```
HTML 이메일 제품 소개 섹션 (2열: 이미지 좌 + 텍스트 우).

좌측 (260px):
- 제품 이미지 (260×260px)

우측 (280px):
- 제품명 (20px, 굵게)
- 특징 3개 (불릿 목록, 14px)
- 가격: 정가(취소선) + 할인가 (빨간색, 22px)
- CTA 버튼

모바일에서는 이미지 위, 텍스트 아래로 쌓이게.
Outlook 호환.
```

### 섹션 5. 푸터 (구독 취소 필수)

```
HTML 이메일 푸터 섹션 작성.

포함 요소 (수신거부 링크는 이메일 마케팅 법적 필수):
- 회사명, 주소
- 수신거부 링크 (href="{{unsubscribe_url}}")
- SNS 아이콘 링크 3개 (인스타/유튜브/링크드인)
- 저작권 표시

배경: #f4f4f4
텍스트: 12px, #888888
중앙 정렬
```

---

## 3.4 한 번에 전체 템플릿 요청하기

섹션별로 다 이해했다면, 한 번에 요청하는 방법도 있습니다. 파일을 열어둔 상태에서 Inline Chat(`Ctrl+I`)을 사용하면 더 정확합니다.

```
Gmail·Outlook 호환 HTML 이메일 뉴스레터 템플릿 전체 작성.

브랜드: TimeX 스마트워치
이벤트: 신제품 런칭

구조:
1. 헤더 (로고, 배경 #0A2E4A)
2. 히어로 배너 (이미지 자리 + 헤드라인 + 서브 + CTA 버튼)
3. 3컬럼 혜택 섹션 (수면 추적 / 혈중산소 / 7일 배터리)
4. 제품 상세 (이미지 좌 + 텍스트 우)
5. 리뷰/사회적 증거 (배경 연회색)
6. 최종 CTA 섹션 (배경 #0A2E4A, 흰색 텍스트)
7. 푸터 (수신거부 포함, 법적 필수)

요구사항:
- 최대 너비 600px
- 모든 스타일: 인라인 CSS (Outlook 호환)
- 반응형: @media (max-width: 600px)에서 컬럼 쌓이게
- 다크모드 대응 (prefers-color-scheme: dark)
- 이미지 src는 "https://example.com/image.jpg" 플레이스홀더
- 교체해야 할 텍스트는 {{변수명}} 형식
- Outlook VML 분기처리 포함
```

---

## 3.5 다크모드 대응

요즘 이메일 사용자의 상당수가 다크모드를 씁니다. Copilot에게 명시적으로 요청해야 처리해줍니다.

```
위 이메일 템플릿에 다크모드 CSS 추가.

변경 규칙:
- 본문 배경 #ffffff → #1a1a1a
- 본문 텍스트 #333333 → #e0e0e0
- 헤딩 텍스트 #000000 → #ffffff
- 카드 배경 #f8f8f8 → #2a2a2a
- CTA 버튼은 색상 유지

방법: @media (prefers-color-scheme: dark) 블록 사용
<style> 태그 안에 추가.
변경된 부분에는 HTML 주석으로 표시.
```

---

## 3.6 Litmus/Email on Acid 없이 기본 검증

전문 이메일 테스트 도구 없이도 기본적인 검증이 가능합니다.

**1. 브라우저 미리보기**

생성된 HTML 파일을 Chrome에서 열어서 레이아웃 확인 (`Ctrl+O`)

**2. 개발자 도구 반응형 확인**

Chrome DevTools → `Ctrl+Shift+M` → 너비를 375px(모바일)로 설정

**3. Copilot으로 교차 확인**

```
위 HTML 이메일 코드에서 Outlook 호환성 문제가 될 수 있는 부분을 찾아줘.

체크 항목:
1. flex/grid 사용 여부
2. 인라인 CSS 누락된 부분
3. 이미지 width/height 속성 없는 것
4. <link> 스타일시트 참조
5. 미지원 CSS 속성

발견된 문제마다 수정 코드 제시.
```

---

## 3.7 개인정보 처리 주의 (이메일 마케팅)

HTML 이메일 템플릿에서 반드시 지켜야 할 법적 요건:

| 요건 | 근거 | Copilot 생성 시 주의 |
|------|------|---------------------|
| 수신거부 링크 | 정보통신망법 제50조 | 푸터에 반드시 포함 |
| 발신자 정보 | 동일 법 | 회사명·주소 필수 |
| 광고성 정보 표시 | "(광고)" 문구 | 제목에 "[광고]" 또는 "(광고)" 포함 |
| 개인정보 수집 동의 | 개인정보보호법 | 이메일 수집 단계에서 처리 |

```
위 이메일 템플릿의 푸터에 한국 이메일 마케팅 법적 필수 항목 추가:
- "(광고)" 표시
- 수신거부 링크 ({{unsubscribe_url}})
- 무료 수신거부 안내문구
- 발신자 회사명 및 주소 자리
```

---

## 실습: 신제품 런칭 이메일 완성

### 목표

TimeX Pro 신제품 런칭을 알리는 HTML 이메일 완성본 제작

### Step 1. 파일 준비 (5분)

VS Code에서 `timex-launch-email.html` 파일 생성.

### Step 2. 전체 템플릿 생성 (15분)

새 파일에서 Inline Chat(`Ctrl+I`) 실행:

```
Gmail·Outlook 호환 HTML 이메일 생성. 다음 내용으로:

이메일 제목: TimeX Pro 출시 — 7일 배터리 스마트워치의 새 기준

섹션:
1. 헤더: 로고 중앙, 배경 #0A2E4A, 흰색 로고 텍스트 "TimeX"
2. 히어로: 배너 이미지 자리 (600×300), 헤드라인 "수면부터 운동까지, 7일이면 충분합니다", CTA "지금 알아보기" (#E8501A 버튼)
3. 3혜택: [수면 추적 | 혈중산소 측정 | 7일 배터리] 아이콘+제목+설명
4. 제품 상세: 이미지 우측, 좌측에 특징 4개 불릿, 가격 199,000원, 얼리버드 특가 149,000원 (빨간색), CTA "얼리버드 구매"
5. 리뷰: 별점 4.8 / 고객 3인 한줄 후기
6. 최종 CTA: 배경 #0A2E4A, "얼리버드 마감 D-3" 흰색, 버튼 "#E8501A"
7. 푸터: 수신거부 링크, (광고) 표시, 주소 자리

요구사항:
- 인라인 CSS 위주 (Outlook 호환)
- @media (max-width: 600px) 반응형
- 교체 필요 항목은 {{변수명}}으로 표시
- 최대 너비 600px
```

### Step 3. 브라우저에서 확인 (5분)

- Chrome에서 파일 열기 (`Ctrl+O`)
- DevTools 반응형 모드로 모바일 확인 (375px)

### Step 4. Outlook 호환성 점검 (5분)

```
위 HTML 이메일 코드의 Outlook 호환성 문제를 모두 찾아서 수정해줘.
특히 flex, grid, position, background-image 사용 여부 확인.
각 수정 항목에 주석으로 수정 이유 표시.
```

### Step 5. 교체 항목 체크리스트 만들기 (5분)

```
위 HTML 이메일에서 실제 발송 전에 교체해야 할 {{변수명}} 항목들을
체크리스트 Markdown으로 정리해줘.

형식:
- [ ] {{변수명}}: 교체할 내용 설명
```

---

## 핵심 포인트

1. **HTML 이메일 = table 기반** — flex·grid는 Outlook에서 깨짐
2. **스타일은 인라인 CSS** — `<link>` 스타일시트는 지원 안 됨
3. **이미지는 항상 width·height 속성** — 지정 안 하면 클라이언트마다 다르게 표시
4. **수신거부 링크는 법적 필수** — 정보통신망법, 프롬프트에 명시
5. **Copilot이 Outlook 호환성을 항상 맞추지 않음** — 생성 후 반드시 교차 검토

---

**다음**: [04-day1-lab.md](./04-day1-lab.md) — Day 1 종합 실습
