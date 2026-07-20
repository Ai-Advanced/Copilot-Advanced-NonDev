# 03. 디자이너를 위한 CSS 최소 지식

## 학습 목표

- CSS를 "배우는" 것이 아니라 Copilot을 통해 "활용하는" 관점으로 접근
- Flexbox와 Grid의 시각적 동작 원리를 그림 없이 이해
- CSS Variables로 디자인 토큰을 컴포넌트에 연결하는 방법 습득
- "이 Figma 디자인을 CSS로 옮겨줘" 식의 프롬프트 작성법 익히기
- 실습: 카드 컴포넌트 CSS 완성

**예상 소요**: 60분

---

## 3.1 디자이너가 CSS를 배워야 하는 이유

CSS를 깊이 배울 필요는 없습니다. 하지만 이 3가지를 알면 Copilot과의 대화가 10배 정확해집니다:

1. **CSS 속성 이름**: 대화할 때 쓰는 공통 언어
2. **레이아웃 원리**: "왜 이렇게 됐는지" 이해해야 수정 요청 가능
3. **CSS Variables**: 토큰을 컴포넌트에 연결하는 메커니즘

> **원칙**: 코드를 직접 짜는 게 목표가 아닙니다. Copilot에게 정확히 요청하고, 결과를 검토할 수 있는 수준이 목표입니다.

---

## 3.2 CSS Box Model — 모든 것의 기초

모든 HTML 요소는 박스입니다. 이 박스의 크기를 결정하는 4가지 레이어:

```
┌─────────────────────────────────────┐
│              margin (바깥 여백)       │
│  ┌─────────────────────────────────┐ │
│  │           border (테두리)        │ │
│  │  ┌───────────────────────────┐  │ │
│  │  │        padding (안쪽 여백)  │  │ │
│  │  │  ┌─────────────────────┐  │  │ │
│  │  │  │     content (내용)   │  │  │ │
│  │  │  └─────────────────────┘  │  │ │
│  │  └───────────────────────────┘  │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 핵심 CSS 속성 — 박스 크기

```css
.card {
  /* 크기 */
  width: 320px;          /* 너비 고정 */
  max-width: 100%;       /* 최대 너비 (반응형 필수) */
  height: auto;          /* 높이 내용에 맞게 */

  /* 안쪽 여백 */
  padding: 24px;         /* 상하좌우 동일 */
  padding: 16px 24px;    /* 상하 16px, 좌우 24px */
  padding-top: 16px;     /* 개별 지정 */

  /* 바깥 여백 */
  margin: 0 auto;        /* 상하 0, 좌우 auto = 수평 중앙 정렬 */

  /* 테두리 */
  border: 1px solid #E5E7EB;
  border-radius: 12px;   /* 모서리 둥글기 */
}
```

### box-sizing: border-box (반드시 쓰는 설정)

```css
/* 이게 없으면 padding이 width에 더해져서 크기가 이상해짐 */
*, *::before, *::after {
  box-sizing: border-box;
}
/* 이걸 설정하면 width: 320px이 padding 포함한 전체 크기 */
```

---

## 3.3 Flexbox — 1차원 레이아웃

Flexbox는 **한 방향(행 또는 열)으로 요소를 정렬**할 때 사용합니다.

### 시각적 이해

```
flex-direction: row (기본)
┌──────────────────────────────────┐
│ [아이템1] [아이템2] [아이템3]      │  ← 가로로 나열
└──────────────────────────────────┘

flex-direction: column
┌──────────────┐
│  [아이템1]    │
│  [아이템2]    │  ← 세로로 나열
│  [아이템3]    │
└──────────────┘
```

### 핵심 속성 10개

```css
/* 부모 요소에 적용 */
.container {
  display: flex;
  flex-direction: row;          /* 방향: row(가로), column(세로) */
  justify-content: space-between; /* 주축 정렬: flex-start, center, flex-end, space-between, space-around */
  align-items: center;          /* 교차축 정렬: flex-start, center, flex-end, stretch */
  flex-wrap: wrap;              /* 줄 바꿈: nowrap(기본), wrap */
  gap: 16px;                    /* 아이템 간격 (row-gap column-gap 분리도 가능) */
}

/* 자식 요소에 적용 */
.item {
  flex: 1;                      /* 남은 공간 균등 분배 */
  flex: 0 0 200px;              /* grow shrink basis: 고정 200px */
  align-self: flex-start;       /* 이 아이템만 개별 정렬 */
}
```

### 자주 쓰는 패턴

**패턴 1. 내비게이션 바 (로고 좌측, 버튼 우측)**

```css
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  height: 64px;
}
```

**패턴 2. 카드 내부 (수직 정렬, footer를 하단에 붙이기)**

```css
.card {
  display: flex;
  flex-direction: column;
  height: 100%;           /* 부모 높이에 맞춤 */
}
.card-body {
  flex: 1;                /* 남은 공간 모두 차지 */
}
.card-footer {
  margin-top: auto;       /* 항상 하단에 위치 */
}
```

**패턴 3. 아이콘 + 텍스트 (수평 정렬)**

```css
.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
}
```

### Copilot에게 Flexbox 요청하는 법

```
아래 레이아웃을 Flexbox CSS로 만들어줘:
- 가로 행
- 왼쪽: 로고 (너비 고정 120px)
- 중앙: 네비 링크 3개 (균등 간격)
- 오른쪽: 버튼 2개 (gap 8px)
- 세로 중앙 정렬
- 높이 64px
```

---

## 3.4 CSS Grid — 2차원 레이아웃

Grid는 **행과 열 모두를 동시에 제어**할 때 사용합니다.

### 시각적 이해

```
grid-template-columns: repeat(3, 1fr)
┌──────────┬──────────┬──────────┐
│ [카드1]  │ [카드2]  │ [카드3]  │
├──────────┼──────────┼──────────┤
│ [카드4]  │ [카드5]  │ [카드6]  │
└──────────┴──────────┴──────────┘
```

### 핵심 속성

```css
.grid-container {
  display: grid;
  grid-template-columns: repeat(3, 1fr);   /* 3열, 동일 너비 */
  grid-template-columns: 240px 1fr;        /* 사이드바 + 메인 */
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); /* 반응형 */
  gap: 24px;                               /* 행/열 간격 */
  row-gap: 32px;                           /* 행 간격만 */
  column-gap: 16px;                        /* 열 간격만 */
}

/* 특정 아이템이 여러 열/행 차지 */
.featured-card {
  grid-column: span 2;       /* 2열 차지 */
  grid-column: 1 / -1;       /* 전체 너비 */
  grid-row: span 2;          /* 2행 차지 */
}
```

### 자주 쓰는 패턴

**패턴 1. 반응형 카드 그리드**

```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}
/* 화면 너비에 따라 열 수가 자동으로 1~4열로 변함 */
```

**패턴 2. 대시보드 레이아웃 (사이드바 + 메인)**

```css
.dashboard {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-rows: 64px 1fr;
  min-height: 100vh;
}
.header { grid-column: 1 / -1; }    /* 헤더는 전체 너비 */
.sidebar { grid-row: 2; }
.main { grid-row: 2; }
```

**패턴 3. 2열 피처 섹션 (이미지 + 텍스트 교차)**

```css
.feature-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 48px;
  align-items: center;
}
/* 짝수 섹션은 이미지/텍스트 순서 반전 */
.feature-section:nth-child(even) .feature-image {
  order: 2;
}
```

---

## 3.5 CSS Variables — 토큰을 컴포넌트에 연결

이전 챕터에서 만든 디자인 토큰을 실제 컴포넌트 CSS에 연결하는 방법입니다.

### 기본 사용법

```css
/* tokens.css에서 정의된 변수를 사용 */
.button-primary {
  background-color: var(--token-color-semantic-brand-default);
  color: var(--token-color-semantic-text-inverse);
  padding: var(--token-spacing-3) var(--token-spacing-6);
  border-radius: var(--token-border-radius-md);
  font-size: var(--token-font-size-sm);
  font-weight: var(--token-font-weight-medium);
}

/* 다크모드는 tokens.css가 자동으로 처리 — 컴포넌트 CSS 건드릴 필요 없음 */
```

### 변수가 없을 때의 폴백 값

```css
.card {
  /* 토큰 변수가 없는 경우 fallback 값 사용 */
  background: var(--token-color-semantic-bg-default, #FFFFFF);
  border-radius: var(--token-border-radius-lg, 12px);
}
```

### 컴포넌트 수준 변수 (로컬 변수)

```css
/* 버튼 자체적인 변수 정의 — 외부에서 재정의 가능 */
.btn {
  --btn-bg: var(--token-color-semantic-brand-default);
  --btn-text: white;
  --btn-radius: var(--token-border-radius-md);
  --btn-padding-x: var(--token-spacing-4);
  --btn-padding-y: var(--token-spacing-2);

  background-color: var(--btn-bg);
  color: var(--btn-text);
  border-radius: var(--btn-radius);
  padding: var(--btn-padding-y) var(--btn-padding-x);
}

/* 위험 버튼: --btn-bg만 덮어쓰기 */
.btn-danger {
  --btn-bg: var(--token-color-semantic-feedback-error-bg, #DC2626);
}
```

---

## 3.6 Copilot에게 CSS 요청하는 패턴

### "이 Figma 스펙 → CSS로" 패턴

Figma의 Inspect 패널에서 보이는 값들을 그대로 Copilot에게 전달합니다.

```
아래 Figma 스펙을 CSS로 만들어줘.

컴포넌트: 알림 배너 (Alert Banner)
크기: 너비 100%, 높이 auto
패딩: 상하 12px, 좌우 16px
배경: #FEF3C7 (warning 상태)
테두리: 1px solid #FDE68A, 왼쪽만 4px solid #F59E0B
모서리: 8px
레이아웃: 아이콘(20px) + 텍스트 (flex row, 가운데 정렬, gap 12px)
폰트: 14px, color #92400E

States:
- info: 배경 #EFF6FF, 테두리 #BFDBFE/#2563EB, 텍스트 #1E40AF
- success: 배경 #F0FDF4, 테두리 #BBF7D0/#16A34A, 텍스트 #166534
- error: 배경 #FEF2F2, 테두리 #FECACA/#DC2626, 텍스트 #991B1B

CSS variables 사용, BEM 클래스 명명, 완전한 코드.
```

### BAD vs GOOD 비교

| 구분 | 프롬프트 | 결과 |
|------|----------|------|
| ❌ BAD | "카드 CSS 만들어줘" | 아무 카드나 나옴 |
| ✅ GOOD | "카드 CSS: 패딩 24px, border-radius 12px, 그림자 0 1px 3px rgba(0,0,0,0.1), hover 시 translateY(-2px) + 그림자 강화, 200ms ease, CSS variables 사용" | 정확한 카드 |
| ❌ BAD | "반응형으로 수정해줘" | 어떻게 반응형인지 모름 |
| ✅ GOOD | "768px 이하에서 2열 → 1열, 폰트 16px → 14px, 패딩 24px → 16px로 수정해줘" | 명확한 수정 |
| ❌ BAD | "다크모드 추가해줘" | 임의의 다크모드 |
| ✅ GOOD | "@media prefers-color-scheme: dark 추가. bg #0F172A, text #F1F5F9, border #334155로" | 정확한 다크모드 |

---

## 3.7 자주 쓰는 CSS 패턴 모음

### 반응형 이미지

```css
.responsive-image {
  width: 100%;
  height: auto;             /* 비율 유지 */
  object-fit: cover;        /* 컨테이너 채우기 (비율 유지, 잘림) */
  object-fit: contain;      /* 컨테이너 안에 맞추기 (여백 생김) */
  aspect-ratio: 16 / 9;     /* 비율 고정 */
}
```

### 텍스트 줄임표

```css
/* 한 줄 줄임표 */
.text-ellipsis {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 여러 줄 줄임표 (2줄) */
.text-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```

### 중앙 정렬

```css
/* Flexbox 중앙 정렬 */
.center-flex {
  display: flex;
  justify-content: center;
  align-items: center;
}

/* 절대 위치 중앙 정렬 */
.center-absolute {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
```

### 스크롤 컨테이너

```css
.scroll-container {
  overflow-y: auto;
  max-height: 400px;
  /* 스크롤바 스타일링 */
  scrollbar-width: thin;
  scrollbar-color: #D1D5DB transparent;
}
```

---

## 실습

### 실습: 카드 컴포넌트 CSS 완성

**목표**: Figma 스펙을 받아서 실제로 작동하는 카드 컴포넌트 CSS를 Copilot으로 만들고 브라우저에서 확인합니다.

**단계 1. HTML 구조 파일 생성**

`card-demo.html` 파일 생성 후 Chat에:

```
아래 카드 컴포넌트용 HTML 구조를 만들어줘.

카드 구조:
- .card (컨테이너)
  - .card-image (16:9 이미지 영역, 실제 이미지 없이 #E5E7EB 배경색 placeholder)
  - .card-body
    - .card-tag (예: "디자인" 태그, 작은 배지 스타일)
    - .card-title (제목)
    - .card-description (설명 텍스트, 2줄 clamp)
  - .card-footer
    - .card-author (프로필 원형 + 이름)
    - .card-date

카드 3개를 .card-grid에 담아서 보여줘.
외부 CSS 파일 card.css를 link로 연결.
완전한 HTML.
```

**단계 2. CSS 파일 생성**

`card.css` 파일 생성 후 Chat에:

```
위 HTML 구조에 맞는 카드 컴포넌트 CSS를 만들어줘.

카드 스펙:
- 배경: white, border: 1px solid #E5E7EB
- border-radius: 12px
- 그림자: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.05)
- hover: translateY(-4px), 그림자 강화, transition 250ms ease

이미지 영역:
- aspect-ratio: 16/9, object-fit: cover
- 상단 border-radius 12px 유지

태그 배지:
- 배경 #EFF6FF, 색상 #2563EB
- padding 2px 10px, border-radius 9999px
- font-size 12px, font-weight 500

제목: font-size 18px, font-weight 600, color #111827
설명: font-size 14px, color #6B7280, -webkit-line-clamp: 2

footer: flex, space-between, border-top 1px solid #F3F4F6
프로필 원형: 32px × 32px, border-radius 50%, 배경 #E5E7EB

카드 그리드: repeat(auto-fill, minmax(300px, 1fr)), gap 24px

CSS variables 사용, 완전한 코드.
```

**단계 3. Live Server로 확인**

1. `card-demo.html` 파일 오른쪽 클릭 → "Open with Live Server"
2. 브라우저에서 카드 3개 확인
3. 마우스 hover 시 애니메이션 확인

**단계 4. 반응형 추가**

```
위 card.css에 반응형 미디어 쿼리를 추가해줘.

768px 이하: 카드 그리드 1열
480px 이하: 카드 패딩 16px로 줄임, 제목 폰트 16px
```

**완성 체크**

- [ ] 카드 3개가 그리드로 표시됨
- [ ] hover 시 위로 살짝 올라가는 애니메이션 작동
- [ ] 브라우저 창 줄이면 1열로 변환됨
- [ ] 이미지 영역이 16:9 비율 유지

---

## 핵심 포인트

1. **Box Model 4 레이어**: margin → border → padding → content
2. **Flexbox = 1차원**: 가로 또는 세로 한 방향 정렬, `justify-content` + `align-items`
3. **Grid = 2차원**: 행과 열 동시 제어, `repeat(auto-fill, minmax())` 패턴이 반응형 핵심
4. **CSS Variables**: 토큰과 컴포넌트를 연결하는 다리 — `var(--token-이름)` 형식
5. **Copilot 요청 시**: 구체적인 px 값, 색상, 상태, 애니메이션 duration 명시

---

**다음 문서**: [04-day1-lab.md](./04-day1-lab.md) — Day 1 종합 실습
