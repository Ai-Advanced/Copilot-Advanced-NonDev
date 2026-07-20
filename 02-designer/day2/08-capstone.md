# 08. 캡스톤 프로젝트 — SaaS 대시보드 디자인 시스템 + 프로토타입

## 학습 목표

- 2일 과정에서 배운 모든 것을 하나의 실전 프로젝트로 통합
- 디자인 토큰 → 컴포넌트 스펙 5개 → HTML 페이지 → 접근성 검증 → 개발자 handoff까지 완성
- 실무에서 바로 쓸 수 있는 deliverable 패키지 만들기

**예상 소요**: 90분

---

## 프로젝트 개요

> **클라이언트 브리핑**
>
> B2B SaaS 스타트업 "DataFlow"가 새 대시보드 앱을 출시합니다.
> 디자인 시스템과 핵심 화면의 HTML 프로토타입을 개발팀에게 넘겨야 합니다.
> 납기는 오늘 EOD입니다.

### 결과물

```
dataflow/
├── design-system/
│   ├── tokens.json              # 디자인 토큰 전체
│   ├── tokens.css               # CSS Variables
│   └── specs/
│       ├── button.md            # 컴포넌트 스펙
│       ├── card.md
│       ├── badge.md
│       ├── input.md
│       └── table.md
├── prototype/
│   ├── index.html               # 대시보드 메인 페이지
│   └── styles.css               # 전체 스타일
└── handoff/
    └── README.md                # 개발자 handoff 문서
```

---

## Phase 1. 디자인 토큰 (20분)

### 1-A. 토큰 생성

`design-system/tokens.json` 파일을 열고 Chat:

```
DataFlow SaaS 대시보드 디자인 토큰을 만들어줘.

브랜드: B2B SaaS, 신뢰감 있고 깔끔한 느낌
Primary: #4F46E5 (인디고 — 집중, 신뢰)
Secondary: #06B6D4 (시안 — 데이터, 분석)
Neutral: #64748B (슬레이트)

포함할 것:
1. color.primary: 50~900 스케일
2. color.secondary: 50~900 스케일
3. color.neutral: 50~900 스케일
4. color.success/warning/error: 100/300/500/700
5. semantic (라이트 모드): text/bg/border/brand
6. semantic (다크 모드): 동일 이름, 다른 값

typography:
- fontFamily.sans: "Inter, -apple-system, sans-serif"
- fontSize: xs~4xl 스케일
- fontWeight: regular/medium/semibold/bold
- lineHeight: tight/normal/relaxed

spacing: 4px 배수 (0~24)
borderRadius: sm(6px)/md(8px)/lg(12px)/xl(16px)/full
shadow: sm/md/lg

W3C DTCG JSON 포맷. JSON만.
```

### 1-B. CSS Variables 변환

```
위 tokens.json을 CSS custom properties로 변환해줘.

접두사: --df- (DataFlow)
라이트/다크 모드 모두 포함.
[data-theme="dark"] 지원.
섹션 주석 포함.
CSS만.
```

---

## Phase 2. 컴포넌트 스펙 5개 (25분)

각 스펙 파일을 Chat으로 생성합니다. 아래는 각 파일용 프롬프트입니다.

### 스펙 1. Button (`specs/button.md`)

```
DataFlow 디자인 시스템의 Button 컴포넌트 스펙 Markdown 문서를 작성해줘.

브랜드: --df- 변수 기준, primary #4F46E5

섹션:
1. 개요 (언제/어떻게 사용)
2. Props 표 (variant/size/disabled/loading/leftIcon/rightIcon/fullWidth/onClick)
3. Variants 표 (primary/secondary/ghost/danger/link)
4. States 표 (default/hover/active/focus/disabled/loading)
5. 접근성 (ARIA, 키보드, 스크린 리더)
6. DO/DON'T (각 5개)
7. 변경 이력 (2026-07-20 | v1.0 | 초기 생성)
```

### 스펙 2. Card (`specs/card.md`)

```
DataFlow Card 컴포넌트 스펙 Markdown 문서.

Card 종류:
1. StatCard: 숫자/KPI 표시 (아이콘, 수치, 레이블, 변화율 배지)
2. ContentCard: 제목+내용+액션 일반 카드
3. ChartCard: 차트 영역이 있는 카드 (차트 자체는 별도 컴포넌트)

섹션:
1. 개요
2. Props 표 (title/subtitle/icon/value/change/loading/actions/children)
3. Variants 표 (stat/content/chart)
4. States (default/loading/empty/error)
5. 접근성
6. DO/DON'T (각 3개)
```

### 스펙 3. Badge (`specs/badge.md`)

```
DataFlow Badge 컴포넌트 스펙 Markdown 문서.

Badge 용도: 상태 표시, 태그, 수량 표시, 알림 카운트

Props: label, variant, size, dot (dot-only 모드)
Variants: default/primary/success/warning/error/info
Sizes: sm/md/lg

접근성: 색만으로 의미 전달 금지 (텍스트+색 함께), 
카운트 배지의 aria-label 처리

DO/DON'T 포함.
```

### 스펙 4. Input (`specs/input.md`)

```
DataFlow Input 컴포넌트 스펙 Markdown 문서.

Input Types: text, email, password, number, search, textarea

Props: type/placeholder/value/disabled/readOnly/error/hint/label/required/
       leftIcon/rightIcon/maxLength/onChange

States: default/focus/error/disabled/readOnly

접근성:
- label 필수 (시각적으로 숨기더라도 aria-label)
- 에러 메시지: aria-describedby로 input과 연결
- required: aria-required="true"

DO/DON'T:
- placeholder를 label 대신 쓰지 말 것
- 에러는 색+텍스트+아이콘으로 (색만 X)
```

### 스펙 5. Table (`specs/table.md`)

```
DataFlow Table 컴포넌트 스펙 Markdown 문서.

Table 기능: 데이터 목록 표시, 정렬, 선택, 페이지네이션

Props: columns/data/sortable/selectable/loading/emptyText/
       onSort/onSelect/pagination

Column 정의: { key, label, sortable, width, render }

States: default/loading(스켈레톤)/empty(빈 상태 메시지)/error

접근성:
- <table> 시맨틱 사용 (div 테이블 금지)
- 정렬 버튼: aria-sort (ascending/descending/none)
- 선택 체크박스: aria-label "행 선택"
- 헤더: <th scope="col">

Responsive: 모바일에서 가로 스크롤 또는 카드 뷰로 전환

DO/DON'T 포함.
```

---

## Phase 3. 대시보드 HTML 프로토타입 (30분)

### 3-A. 레이아웃 구조

`prototype/index.html` 파일 생성 후:

```
SaaS 대시보드 메인 페이지 HTML/CSS를 만들어줘.

외부 파일:
- ../design-system/tokens.css (CSS variables)
- prototype/styles.css

레이아웃 구조:
- .app-layout: grid, 전체 viewport 높이
  - .sidebar (240px, 고정): 로고, 내비게이션, 하단 유저 정보
  - .main-area
    - .topbar (64px, sticky): 페이지 제목, 검색, 알림벨, 아바타
    - .page-content (스크롤): 대시보드 콘텐츠

모바일 (768px 이하): 사이드바 숨김, 햄버거 버튼, 오버레이 드로어

sidebar 스타일:
- 배경 --df-color-bg-default, border-right 1px
- 로고: 상단 32px, 내 높이 64px
- nav 링크: 아이콘(이모지) + 텍스트, padding 10px 16px
- active 링크: 배경 brand.subtle, 텍스트 brand.default, 왼쪽 3px border
- hover: 배경 neutral.50

topbar 스타일:
- 배경 white, border-bottom 1px, padding 0 24px
- flex, space-between, align center

완전한 HTML + styles.css 코드 블록.
```

### 3-B. 대시보드 콘텐츠

`prototype/index.html`의 `.page-content` 안에 추가:

```
대시보드 메인 콘텐츠 HTML/CSS를 만들어줘.

섹션 1 - 상단 KPI 카드 (4개, 2x2 그리드, 1200px+ 4열):
- 총 사용자: 수치 12,847, 전월 대비 +12.3% (success badge)
- 월 매출: $48,290, 전월 대비 +8.1% (success badge)
- 활성 세션: 1,429, 전월 대비 -2.4% (error badge)
- 전환율: 3.24%, 전월 대비 +0.8% (success badge)

각 카드:
- 배경 white, border 1px, border-radius 12px, padding 24px
- 상단: 아이콘(이모지 48px) + 제목
- 수치: font-size 32px, font-weight 700
- 변화율 배지: 배경 success/error, 작은 텍스트

섹션 2 - 차트 + 테이블 2열 레이아웃:
왼쪽 (60%): 라인 차트 placeholder (배경 #F8FAFC, "차트 영역" 텍스트, 고정 높이 300px)
오른쪽 (40%): 최근 거래 목록 5개 (아이콘, 이름, 금액, 상태 배지)

섹션 3 - 사용자 테이블:
헤더 (이름/이메일/가입일/플랜/상태/액션 6열)
행 5개 (더미 데이터)
하단 페이지네이션 (이전/1/2/3/.../다음)

--df- CSS variables 사용. 완전한 HTML + 추가 CSS.
```

### 3-C. 반응형 + 접근성 마무리

```
prototype/index.html과 styles.css를 검토하고:

1. 반응형 수정:
   - 768px 이하: 사이드바 숨김, 햄버거 버튼 표시
   - KPI 카드: 2열 (모바일 1열)
   - 테이블: 가로 스크롤

2. 접근성:
   - <nav> aria-label 추가
   - 테이블 <th scope="col">
   - 아이콘 버튼 aria-label
   - :focus-visible 스타일

3. 다크모드 토글 버튼 (topbar 우측)

수정된 HTML과 추가 CSS 제공.
```

---

## Phase 4. 개발자 Handoff 문서 (15분)

`handoff/README.md` 파일 생성 후:

```
DataFlow 디자인 시스템 개발자 handoff 문서를 Markdown으로 작성해줘.

문서 이름: DataFlow Design System — Developer Handoff Guide
버전: v1.0
작성자: [디자이너 이름]
날짜: 2026-07-20

섹션 구성:

## 1. 시작하기
- CSS 파일 로드 순서 (tokens.css 먼저)
- HTML 기본 구조
- 다크모드 사용법

## 2. 디자인 토큰
- 변수 접두사 (--df-)
- 컬러 시스템 (기본 + 시맨틱 2계층 설명)
- 주요 변수 표 (가장 많이 쓰는 20개)

## 3. 컴포넌트 스펙 목록
| 컴포넌트 | 버전 | 스펙 파일 | 상태 |
각 5개 컴포넌트 행

## 4. 프로토타입 구조
- 파일 구조 설명
- Live Server 실행 방법
- 주요 CSS 클래스 설명

## 5. 브랜드 가이드라인 요약
- 컬러 (Primary/Secondary 핵심값)
- 타이포그래피
- 간격 원칙

## 6. 알려진 한계 / 향후 작업
- 아직 스펙 없는 컴포넌트 목록
- 주의사항

## 7. 질문 / 피드백
연락처 / 업데이트 방법

전문적이고 간결한 톤. Markdown 형식.
```

---

## Phase 5. 최종 검증 (10분)

### 전체 체크리스트

**디자인 시스템**
- [ ] `tokens.json` 완성 (color/typography/spacing/radius/shadow)
- [ ] `tokens.css` 라이트 + 다크모드 포함
- [ ] 컴포넌트 스펙 5개 완성 (button/card/badge/input/table)
- [ ] 각 스펙에 Props + Variants + States + Accessibility + DO/DON'T

**프로토타입**
- [ ] 사이드바 + topbar + 콘텐츠 레이아웃 작동
- [ ] KPI 카드 4개 표시
- [ ] 차트 placeholder + 거래 목록
- [ ] 사용자 테이블 (헤더 + 행 5개 + 페이지네이션)
- [ ] 모바일 반응형 (사이드바 숨김)
- [ ] 다크모드 토글 작동
- [ ] 키보드 포커스 스타일 보임

**Handoff**
- [ ] `handoff/README.md` 완성
- [ ] CSS 로드 순서 명시
- [ ] 주요 변수 표 포함

### 제출 전 Copilot 최종 검토 요청

```
아래 파일들을 전체적으로 검토하고 개선사항을 알려줘.

검토 파일:
- design-system/tokens.json
- prototype/index.html
- handoff/README.md

검토 관점:
1. 일관성: 변수명, 클래스명, 패턴이 일관한가
2. 완결성: 빠진 것이 있는가
3. 접근성: 주요 위반 사항
4. 실용성: 개발팀이 바로 쓸 수 있는 수준인가

우선순위 순으로 개선사항 5개 이내로 정리.
```

---

## 보너스 — 실제 프로젝트 적용 힌트

### 기존 프로젝트에 이 방식 도입하기

이미 진행 중인 프로젝트에 오늘 배운 방식을 적용하려면:

**단계 1. 현재 CSS에서 토큰 추출**

```
아래 CSS에서 반복 사용되는 색상, 간격, 폰트 크기를 추출해서
디자인 토큰 JSON으로 만들어줘.

[기존 CSS 붙여넣기]

추출 기준:
- 같은 값이 3번 이상 반복되는 것
- 색상은 의미 기반 이름으로 (예: "brand" not "blue")
```

**단계 2. 점진적 마이그레이션**

한 번에 전체를 바꾸지 않고, 새로 만드는 컴포넌트부터 토큰 적용.

**단계 3. 팀에 공유**

```
아래 내용을 팀에게 설명하는 2분 발표 슬라이드 개요를 만들어줘.

주제: "우리 팀이 디자인 토큰을 도입해야 하는 이유"
내용: 현재 문제점, 토큰의 이점, 도입 3단계 계획
청중: 디자이너 + 개발자 혼합
톤: 설득력 있고 간결하게

슬라이드 5장 개요 (각 슬라이드 제목 + 핵심 포인트 3개).
```

---

## 핵심 포인트

1. **A~Z 흐름**: 토큰 → 스펙 → 프로토타입 → 접근성 → 핸드오프 — 이 순서가 실무 흐름
2. **토큰이 기반**: CSS variables 없이 시작하면 다크모드, 브랜드 변경이 2배 힘들어짐
3. **스펙은 슬랙 20개 예방**: Props/States/A11y 명시가 개발자와의 커뮤니케이션 비용 절감
4. **프로토타입은 도구, Figma도 도구**: 상황에 맞는 도구를 쓰는 것이 중요
5. **Copilot은 초안 생성기**: 검토와 조정은 항상 사람이 — AI가 놓친 것을 잡는 것도 디자이너의 역량

---

## 2일 과정 수료

**오늘 만든 것들**

| 결과물 | 챕터 |
|--------|------|
| 디자인 토큰 JSON (W3C DTCG) | 02, 캡스톤 |
| CSS Variables (라이트/다크) | 02, 캡스톤 |
| 카드 컴포넌트 CSS | 03, 04 |
| Lumio 브랜드 3컴포넌트 | 04 |
| Button 스펙 문서 | 05 |
| 랜딩 페이지 프로토타입 | 06 |
| 접근성 감사 + 수정 | 07 |
| DataFlow 디자인 시스템 | 캡스톤 |

**다음 단계**

- `prompts.md`의 프롬프트를 북마크해서 실무에서 즉시 활용
- 현재 진행 중인 프로젝트의 디자인 토큰을 Copilot으로 추출해보기
- 팀 개발자에게 handoff 문서 포맷을 공유하고 피드백 받기

---

**관련 자료**:
- [prompts.md](../prompts.md) — 전체 프롬프트 치트시트
- [design-tokens-starter.json](../resources/templates/design-tokens-starter.json) — 시작 템플릿
- [component-spec-template.md](../resources/templates/component-spec-template.md) — 스펙 문서 템플릿
- [sample-landing-page.html](../resources/examples/sample-landing-page.html) — 완성 예시
