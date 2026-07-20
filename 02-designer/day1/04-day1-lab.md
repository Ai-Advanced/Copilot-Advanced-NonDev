# 04. Day 1 종합 실습 — 브랜드 리브랜딩 프로젝트

## 학습 목표

- Day 1에서 배운 토큰 + CSS를 하나의 실전 시나리오로 통합
- 브랜드 컬러 팔레트 → 디자인 토큰 JSON → 3개 컴포넌트 CSS까지 A~Z 완성
- Copilot 대화를 점진적으로 쌓아가는 방식 훈련

**예상 소요**: 60분

---

## 시나리오

> 스타트업 "Lumio"가 리브랜딩을 결정했습니다. 새 브랜드 가이드라인이 나왔고,
> 디자인 토큰과 핵심 컴포넌트 CSS를 새 브랜드에 맞게 준비해달라는 요청을 받았습니다.

**새 브랜드 정보**

| 항목 | 값 |
|------|-----|
| 브랜드 이름 | Lumio |
| Primary | `#F97316` (오렌지, 따뜻하고 에너지 넘치는) |
| Secondary | `#0EA5E9` (스카이 블루, 신뢰와 명료함) |
| Neutral | `#374151` (다크 그레이) |
| 폰트 | `"Pretendard, -apple-system, sans-serif"` |
| 스타일 | 둥글고 친근하게, border-radius 넉넉히 |

**결과물 목록**

```
lumio-tokens/
├── tokens.json          # 전체 디자인 토큰
├── tokens.css           # CSS Variables
└── components/
    ├── button.css       # 버튼 컴포넌트
    ├── card.css         # 카드 컴포넌트
    └── badge.css        # 배지 컴포넌트
demo.html                # 3개 컴포넌트 확인 페이지
```

---

## 단계별 실습

### Step 1. 프로젝트 폴더 설정 (5분)

VS Code에서 새 폴더 `lumio-rebrand`를 만들고 위 구조대로 빈 파일들을 생성합니다.

```
mkdir lumio-rebrand
cd lumio-rebrand
mkdir lumio-tokens
mkdir lumio-tokens/components
```

---

### Step 2. 디자인 토큰 생성 (15분)

`tokens.json` 파일을 열고 Chat 사이드바에서:

**프롬프트 2-A: 기본 컬러 스케일**

```
Lumio 브랜드 디자인 토큰 tokens.json을 만들어줘.

브랜드 컬러:
- primary: #F97316 (오렌지) 기준 50~900 스케일
- secondary: #0EA5E9 (스카이 블루) 기준 50~900 스케일
- neutral: #374151 (다크 그레이) 기준 50~900 스케일
- success: #22C55E 기준 100/300/500/700
- error: #EF4444 기준 100/300/500/700
- warning: #EAB308 기준 100/300/500/700

W3C DTCG 포맷. 다음 구조:
{
  "color": {
    "primary": { "50": {...}, "100": {...}, ... "900": {...} },
    ...
  }
}

JSON만 반환.
```

결과를 `tokens.json`에 붙여넣기.

**프롬프트 2-B: 시맨틱 + 타이포그래피 + 간격 추가**

```
위 tokens.json에 다음을 추가해줘.

semantic 컬러 (라이트 모드):
- text.primary → neutral.900
- text.secondary → neutral.600
- text.disabled → neutral.400
- bg.default → #FFFFFF
- bg.subtle → neutral.50
- border.default → neutral.200
- border.strong → neutral.400
- brand.default → primary.500
- brand.subtle → primary.50
- brand.text → primary.700
- feedback.success-bg → success.100, feedback.success-text → success.700
- feedback.error-bg → error.100, feedback.error-text → error.700

typography:
- fontFamily.sans: "Pretendard, -apple-system, BlinkMacSystemFont, sans-serif"
- fontSize: xs(12px), sm(14px), base(16px), lg(18px), xl(20px), 2xl(24px), 3xl(30px)
- fontWeight: regular(400), medium(500), semibold(600), bold(700)
- lineHeight: tight(1.2), normal(1.5), relaxed(1.625)

spacing (4px 배수):
1(4px), 2(8px), 3(12px), 4(16px), 5(20px), 6(24px), 8(32px), 10(40px), 12(48px)

borderRadius:
sm(6px), md(10px), lg(14px), xl(20px), full(9999px)

기존 구조 유지, 추가 섹션만 보여줘. JSON만.
```

결과를 `tokens.json`의 기존 내용 뒤에 병합. (Copilot이 추가 섹션만 준 경우 직접 합치기)

---

### Step 3. CSS Variables 생성 (10분)

`tokens.css` 파일을 열고:

```
위 tokens.json 전체를 CSS custom properties로 변환해줘.

요구사항:
- :root { } 에 모든 토큰
- 변수명: --lumio-color-primary-500, --lumio-spacing-4 등 --lumio- 접두사
- 다크모드 섹션:
  @media (prefers-color-scheme: dark) { :root { ... } }
  [data-theme="dark"] { ... }
  다크모드 값: bg.default → #0F172A, bg.subtle → #1E293B,
  text.primary → #F8FAFC, text.secondary → #94A3B8,
  border.default → #334155, brand.default → primary.400(#FB923C)

- 섹션 주석으로 구분 (/* === Colors === */ 등)

CSS만 반환.
```

결과를 `tokens.css`에 저장.

---

### Step 4. 버튼 컴포넌트 CSS (10분)

`components/button.css` 파일을 열고:

```
Lumio 브랜드의 버튼 컴포넌트 CSS를 만들어줘.

lumio-tokens/tokens.css의 --lumio- 변수 사용.

기본 클래스 .btn:
- display: inline-flex, align-items: center, gap: 8px
- font-family: var(--lumio-font-family-sans)
- font-weight: var(--lumio-font-weight-semibold)
- cursor: pointer, transition: all 150ms ease
- border: none, border-radius: var(--lumio-border-radius-md)
- line-height: 1

크기:
- .btn-sm: padding 8px 16px, font-size 12px
- .btn-md (기본): padding 10px 20px, font-size 14px
- .btn-lg: padding 14px 28px, font-size 16px

Variants:
- .btn-primary: bg var(--lumio-color-brand-default), text white
  hover: bg primary.600 (#EA580C), active: scale(0.98)
- .btn-secondary: bg #F3F4F6, text neutral.700
  hover: bg neutral.200
- .btn-ghost: bg transparent, text brand.default, border 2px solid brand.default
  hover: bg brand.subtle
- .btn-danger: bg error.500(#EF4444), text white
  hover: bg error.700

States:
- :disabled: opacity 0.5, cursor not-allowed, pointer-events none
- :focus-visible: outline 3px solid brand.subtle, outline-offset 2px

Lumio 특유의 둥근 느낌 살릴 것 (border-radius 넉넉히).
CSS만.
```

---

### Step 5. 카드 컴포넌트 CSS (10분)

`components/card.css` 파일을 열고:

```
Lumio 브랜드의 카드 컴포넌트 CSS를 만들어줘.

--lumio- 변수 사용.

.card:
- background: var(--lumio-color-bg-default)
- border: 1px solid var(--lumio-color-border-default)
- border-radius: var(--lumio-border-radius-xl) (20px, Lumio의 둥근 스타일)
- overflow: hidden
- transition: transform 200ms ease, box-shadow 200ms ease

hover:
- transform: translateY(-4px)
- box-shadow: 0 12px 24px rgba(249, 115, 22, 0.12) (Lumio 오렌지 그림자!)

.card-image: aspect-ratio 16/9, object-fit cover

.card-body: padding var(--lumio-spacing-6)

.card-tag:
- 배경 var(--lumio-color-brand-subtle)
- 색상 var(--lumio-color-brand-text)
- border-radius full
- padding 2px 10px, font-size 12px, font-weight 600

.card-title: font-size 18px, font-weight 700, color text.primary
.card-description: font-size 14px, color text.secondary, -webkit-line-clamp 3

.card-footer:
- padding 16px var(--lumio-spacing-6)
- border-top 1px solid var(--lumio-color-border-default)
- display flex, justify-content space-between, align-items center

CSS만.
```

---

### Step 6. 배지 컴포넌트 CSS (5분)

`components/badge.css` 파일을 열고:

```
Lumio 브랜드 배지(Badge) 컴포넌트 CSS를 만들어줘.

--lumio- 변수 사용.

.badge 기본:
- display: inline-flex, align-items: center, gap: 4px
- padding: 3px 10px
- border-radius: var(--lumio-border-radius-full)
- font-size: 12px, font-weight: 600
- line-height: 1.4

Variants:
- .badge-default: bg neutral.100, color neutral.700
- .badge-primary: bg brand.subtle, color brand.text (오렌지 톤)
- .badge-secondary: bg secondary.50, color secondary.700 (블루 톤)
- .badge-success: bg feedback.success-bg, color feedback.success-text
- .badge-error: bg feedback.error-bg, color feedback.error-text
- .badge-warning: bg warning.100, color warning.700

Size:
- .badge-sm: font-size 11px, padding 2px 8px
- .badge-lg: font-size 14px, padding 4px 14px

아이콘 점 (.badge-dot): 6px 원형 dot을 배지 앞에 표시

CSS만.
```

---

### Step 7. 데모 HTML 파일 (5분)

`demo.html` 파일을 열고:

```
Lumio 브랜드 컴포넌트 데모 페이지 HTML을 만들어줘.

CSS 연결:
- lumio-tokens/tokens.css
- lumio-tokens/components/button.css
- lumio-tokens/components/card.css
- lumio-tokens/components/badge.css

페이지 구조:
1. 헤더: "Lumio 디자인 시스템 데모" 제목, 다크모드 토글 버튼
2. 섹션: 버튼 모든 variants + sizes 표시 (라벨 포함)
3. 섹션: 카드 3개 그리드 (각 카드에 배지 포함)
4. 섹션: 배지 모든 variants 표시

다크모드 토글:
document.documentElement.toggleAttribute('data-theme', 'dark') 간단한 JS

body: 배경 var(--lumio-color-bg-subtle), padding 40px
각 섹션: h2 제목 + 내용

완전한 HTML.
```

---

### Step 8. 최종 확인

1. `demo.html` 오른쪽 클릭 → "Open with Live Server"
2. 브라우저에서 확인:

**체크리스트**

- [ ] 버튼 4가지 variants 모두 표시
- [ ] 버튼 hover 시 색상 변화 확인
- [ ] 카드 3개 그리드로 표시
- [ ] 카드 hover 시 오렌지 그림자 + 위로 이동 확인
- [ ] 배지 여러 variants 표시
- [ ] 다크모드 토글 버튼 클릭 시 전환 확인

**문제 발생 시 해결 방법**

| 증상 | 확인할 것 | Copilot 프롬프트 |
|------|-----------|-----------------|
| 색상이 회색 | CSS variable 이름 불일치 | "button.css의 변수명을 tokens.css와 맞춰줘" |
| 레이아웃이 깨짐 | Flexbox/Grid 속성 누락 | "카드 그리드가 1열로만 나와요. 3열로 고쳐줘" |
| 다크모드 안 됨 | JS 또는 data-theme 체크 | "다크모드 토글이 작동 안 해요. JS 수정해줘" |
| 폰트 다름 | Pretendard 미로드 | "Google Fonts 대신 system-ui 폴백 사용하도록 수정" |

---

## 보너스: 개발자 Handoff 메모

실습을 마쳤다면 짧은 handoff 메모를 작성해봅니다.

```
Chat에:
아래 Lumio 디자인 시스템 작업 결과를 개발자 handoff 메모로 정리해줘.

결과물:
- tokens.json: W3C DTCG 포맷 색상/타이포/간격/radius 토큰
- tokens.css: CSS custom properties (라이트/다크모드)
- components/button.css: 4 variants, 3 sizes, disabled/focus 상태
- components/card.css: hover 애니메이션, Lumio 오렌지 그림자
- components/badge.css: 6 variants, 3 sizes

개발자가 알아야 할 것:
- CSS 파일 로드 순서 (tokens.css 먼저)
- 다크모드 토글 방법
- --lumio- 접두사 규칙
- 브랜드 특이사항 (오렌지 그림자, 넉넉한 radius)

Markdown 형식, 1페이지 분량.
```

---

## 핵심 포인트

1. **워크플로우 순서**: 토큰 JSON → CSS Variables → 컴포넌트 CSS → 데모 HTML
2. **변수 접두사**: 프로젝트명 접두사(`--lumio-`)로 다른 라이브러리와 충돌 방지
3. **브랜드 개성**: Lumio의 오렌지 그림자처럼, 브랜드 특유의 느낌을 CSS로 표현
4. **다크모드**: `tokens.css`만 수정하면 모든 컴포넌트에 자동 반영
5. **Copilot 대화 이어가기**: 결과가 완벽하지 않아도 "이 부분 수정해줘"로 점진적 개선

---

**Day 1 완료!**

오늘 배운 것: 디자인 토큰 → JSON → CSS Variables → 컴포넌트 CSS → 브라우저 확인

**Day 2 시작**: [05-component-spec.md](../day2/05-component-spec.md) — 컴포넌트 스펙 문서화
