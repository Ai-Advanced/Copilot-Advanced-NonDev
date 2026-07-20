# 02. 디자인 토큰 관리

## 학습 목표

- 디자인 토큰이 무엇이고 왜 필요한지 이해
- Color / Typography / Spacing 토큰을 JSON으로 구조화하는 방법 습득
- Figma Variables → JSON → CSS Variables 흐름 이해
- Copilot으로 토큰 세트 확장, 다크모드 변환, W3C DTCG 포맷 활용
- 실습: 브랜드 컬러 팔레트 → 완전한 토큰 세트 완성

**예상 소요**: 60분

---

## 2.1 디자인 토큰이란?

디자인 토큰은 **디자인 결정을 저장하는 이름 있는 값**입니다.

색상, 크기, 간격, 폰트 등 디자인에서 반복적으로 사용되는 값들을 코드로 표현한 것입니다.

### 토큰 없이 vs 토큰 있이

**토큰 없이 (위험한 방식)**

```css
/* 여러 파일에 같은 색상이 하드코딩 */
.button { background: #2563EB; }
.link { color: #2563EB; }
.badge { border: 1px solid #2563EB; }
/* 브랜드 컬러를 바꾸면? → 파일 수백 개 전부 검색/교체 */
```

**토큰 있이 (올바른 방식)**

```css
:root {
  --color-brand-default: #2563EB;
}
.button { background: var(--color-brand-default); }
.link { color: var(--color-brand-default); }
.badge { border: 1px solid var(--color-brand-default); }
/* 브랜드 컬러 변경: :root 한 줄만 수정 */
```

### 토큰의 2가지 계층

| 계층 | 이름 | 예시 | 설명 |
|------|------|------|------|
| **기본 토큰** (Primitive) | `color.blue.500` | `#2563EB` | 실제 값, 변경 거의 없음 |
| **시맨틱 토큰** (Semantic) | `color.brand.default` | `{color.blue.500}` 참조 | 의미/역할 기반, 다크모드 전환에 활용 |

이 2계층 구조가 다크모드를 깔끔하게 만드는 핵심입니다.

```
라이트 모드: brand.default → blue.500 (#2563EB)
다크 모드:  brand.default → blue.400 (#60A5FA)

컴포넌트는 brand.default만 사용 → 모드 전환 시 자동으로 색상 변경
```

---

## 2.2 W3C DTCG 포맷 이해

W3C Design Token Community Group(DTCG)에서 표준화한 JSON 포맷입니다. Figma, Style Dictionary, Theo 등 주요 도구들이 이 포맷을 지원합니다.

### 기본 구조

```json
{
  "토큰 이름": {
    "$type": "color",
    "$value": "#2563EB",
    "$description": "기본 브랜드 색상"
  }
}
```

### 핵심 규칙

| 키 | 의미 | 필수 |
|----|------|:----:|
| `$type` | 값의 종류 (color, dimension, fontFamily 등) | 권장 |
| `$value` | 실제 값 | 필수 |
| `$description` | 설명 | 선택 |
| `$extensions` | 도구별 확장 | 선택 |

### 지원하는 `$type` 목록

| 타입 | 사용처 | 값 예시 |
|------|--------|---------|
| `color` | 색상 | `"#2563EB"` |
| `dimension` | 크기, 간격 | `"16px"`, `"1rem"` |
| `fontFamily` | 폰트 | `"Pretendard, sans-serif"` |
| `fontWeight` | 굵기 | `700` |
| `duration` | 애니메이션 시간 | `"200ms"` |
| `cubicBezier` | easing | `[0.16, 1, 0.3, 1]` |
| `shadow` | 그림자 | 객체 형식 |

---

## 2.3 Copilot으로 컬러 토큰 만들기

### 단계 1. 기본 토큰 (10단계 스케일)

VS Code에서 `tokens.json` 파일을 새로 만들고 Chat 사이드바에 입력:

```
다음 브랜드 컬러를 기반으로 W3C DTCG 포맷 컬러 토큰 JSON을 만들어줘.

Primary: #2563EB (파란색 계열)
Secondary: #7C3AED (보라색 계열)
Neutral: #6B7280 (회색 계열)

각 색상마다:
- 50/100/200/300/400/500/600/700/800/900 스케일
- 500이 기준 색상
- 50은 가장 밝음, 900은 가장 어두움
- 각 토큰: $type: "color", $value: hex

구조:
{
  "color": {
    "primary": {
      "50": { "$type": "color", "$value": "..." },
      ...
    }
  }
}

JSON만 반환.
```

Copilot이 이런 결과를 만들어냅니다:

```json
{
  "color": {
    "primary": {
      "50":  { "$type": "color", "$value": "#EFF6FF" },
      "100": { "$type": "color", "$value": "#DBEAFE" },
      "200": { "$type": "color", "$value": "#BFDBFE" },
      "300": { "$type": "color", "$value": "#93C5FD" },
      "400": { "$type": "color", "$value": "#60A5FA" },
      "500": { "$type": "color", "$value": "#2563EB" },
      "600": { "$type": "color", "$value": "#1D4ED8" },
      "700": { "$type": "color", "$value": "#1E40AF" },
      "800": { "$type": "color", "$value": "#1E3A8A" },
      "900": { "$type": "color", "$value": "#1E3A5F" }
    }
  }
}
```

### 단계 2. 시맨틱 토큰 추가

기본 토큰이 준비됐으면, 시맨틱 계층을 추가합니다:

```
위 tokens.json에 시맨틱 토큰을 추가해줘.

semantic 섹션 추가:
- text.primary: neutral.900 참조
- text.secondary: neutral.600 참조
- text.disabled: neutral.400 참조
- text.inverse: neutral.50 참조
- bg.default: neutral.50 참조 (실제값 #FFFFFF 사용)
- bg.subtle: neutral.100 참조
- bg.emphasis: neutral.900 참조
- border.default: neutral.200 참조
- border.strong: neutral.400 참조
- brand.default: primary.500 참조
- brand.subtle: primary.50 참조
- brand.text: primary.700 참조

참조 형식: "$value": "{color.primary.500}"

기존 JSON 구조 유지, semantic 섹션만 추가해서 보여줘.
```

결과 구조:

```json
{
  "color": {
    "primary": { "... 기존 ...": {} },
    "semantic": {
      "text": {
        "primary":   { "$type": "color", "$value": "{color.neutral.900}" },
        "secondary": { "$type": "color", "$value": "{color.neutral.600}" },
        "disabled":  { "$type": "color", "$value": "{color.neutral.400}" }
      },
      "bg": {
        "default": { "$type": "color", "$value": "#FFFFFF" },
        "subtle":  { "$type": "color", "$value": "{color.neutral.50}" }
      },
      "brand": {
        "default": { "$type": "color", "$value": "{color.primary.500}" },
        "subtle":  { "$type": "color", "$value": "{color.primary.50}" }
      }
    }
  }
}
```

---

## 2.4 다크모드 토큰

### 방법 1. 별도 파일로 분리 (권장)

`tokens-dark.json` 파일을 만들어 시맨틱 토큰의 다크모드 값만 재정의:

```
tokens-dark.json을 만들어줘.

라이트 모드 시맨틱 토큰과 동일한 이름을 유지하되,
다크 모드에 적합한 값으로 교체:

배경: #0F172A 기준 계층 구조
텍스트: 밝은 계열 (대비율 WCAG AA 4.5:1 이상)
브랜드: primary.400 또는 primary.300으로 밝게 조정

라이트 모드 값:
- text.primary: #111827
- text.secondary: #6B7280
- bg.default: #FFFFFF
- bg.subtle: #F9FAFB
- border.default: #E5E7EB
- brand.default: #2563EB

W3C DTCG JSON 포맷. JSON만 반환.
```

다크모드 결과 예시:

```json
{
  "color": {
    "semantic": {
      "text": {
        "primary":   { "$type": "color", "$value": "#F1F5F9" },
        "secondary": { "$type": "color", "$value": "#94A3B8" },
        "disabled":  { "$type": "color", "$value": "#475569" }
      },
      "bg": {
        "default": { "$type": "color", "$value": "#0F172A" },
        "subtle":  { "$type": "color", "$value": "#1E293B" }
      },
      "brand": {
        "default": { "$type": "color", "$value": "#60A5FA" }
      }
    }
  }
}
```

### 방법 2. CSS Variables로 변환 (개발팀 전달용)

```
위 tokens.json과 tokens-dark.json을 CSS custom properties로 변환해줘.

요구사항:
- :root { } 안에 라이트 모드 값
- @media (prefers-color-scheme: dark) { :root { } } 안에 다크 모드 값
- data-theme="dark" 속성으로도 전환 가능하도록
- 변수명: --token-color-semantic-text-primary 형식
- 섹션 주석 포함

CSS만 반환.
```

결과:

```css
/* ===== Design Tokens: Light Mode ===== */
:root {
  /* Text */
  --token-color-semantic-text-primary:   #111827;
  --token-color-semantic-text-secondary: #6B7280;
  --token-color-semantic-text-disabled:  #9CA3AF;

  /* Background */
  --token-color-semantic-bg-default: #FFFFFF;
  --token-color-semantic-bg-subtle:  #F9FAFB;

  /* Brand */
  --token-color-semantic-brand-default: #2563EB;
  --token-color-semantic-brand-subtle:  #EFF6FF;
}

/* ===== Design Tokens: Dark Mode ===== */
@media (prefers-color-scheme: dark) {
  :root {
    --token-color-semantic-text-primary:   #F1F5F9;
    --token-color-semantic-text-secondary: #94A3B8;
    --token-color-semantic-bg-default:     #0F172A;
    --token-color-semantic-bg-subtle:      #1E293B;
    --token-color-semantic-brand-default:  #60A5FA;
  }
}

[data-theme="dark"] {
  --token-color-semantic-text-primary:   #F1F5F9;
  /* ... 동일하게 반복 */
}
```

---

## 2.5 타이포그래피 토큰

### 폰트 스케일 생성

```
타이포그래피 디자인 토큰 JSON을 만들어줘.

fontFamily:
- sans: "Pretendard, -apple-system, BlinkMacSystemFont, sans-serif"
- mono: "JetBrains Mono, 'Courier New', monospace"

fontSize 스케일 (이름: px 값):
xs: 12px, sm: 14px, base: 16px, lg: 18px
xl: 20px, 2xl: 24px, 3xl: 30px, 4xl: 36px, 5xl: 48px

lineHeight:
tight: 1.2, snug: 1.35, normal: 1.5, relaxed: 1.625, loose: 2

letterSpacing:
tighter: -0.05em, tight: -0.025em, normal: 0em
wide: 0.025em, wider: 0.05em, widest: 0.1em

fontWeight:
light: 300, regular: 400, medium: 500, semibold: 600, bold: 700

$type: "dimension" (fontSize, lineHeight, letterSpacing, fontFamily, fontWeight에 맞게)
W3C DTCG JSON 포맷. JSON만 반환.
```

---

## 2.6 간격(Spacing) & 기타 토큰

### 간격, 모서리, 그림자

```
다음 토큰들의 W3C DTCG JSON을 만들어줘.

spacing (4px 배수):
0: 0px, 1: 4px, 2: 8px, 3: 12px, 4: 16px, 5: 20px
6: 24px, 8: 32px, 10: 40px, 12: 48px, 16: 64px, 20: 80px, 24: 96px

borderRadius:
none: 0px, sm: 4px, md: 8px, lg: 12px
xl: 16px, 2xl: 24px, 3xl: 32px, full: 9999px

borderWidth:
thin: 1px, medium: 2px, thick: 4px

shadow (box-shadow 값):
sm: "0 1px 2px rgba(0,0,0,0.05)"
md: "0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)"
lg: "0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.06)"
xl: "0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05)"
2xl: "0 25px 50px rgba(0,0,0,0.25)"

$type: "dimension" (spacing, borderRadius, borderWidth), "shadow" (shadow)
JSON만 반환.
```

---

## 2.7 Figma Variables → JSON 변환 워크플로우

### 실제 워크플로우

Figma에서 Variables를 정의했을 때, JSON으로 옮기는 방법입니다.

**방법 1. 플러그인 활용 (권장)**

Figma 플러그인 "Tokens Studio for Figma"를 사용하면 JSON 직접 내보내기가 가능합니다. 하지만 무료 플랜에서는 기능이 제한됩니다.

**방법 2. Copilot으로 수동 변환**

Figma에서 Variables 패널을 보며 값을 Copilot에게 전달:

```
Figma Variables에서 뽑은 아래 정보를 W3C DTCG JSON으로 변환해줘.

Color/Primary:
- Primary/100: #DBEAFE
- Primary/300: #93C5FD
- Primary/500: #2563EB (기준)
- Primary/700: #1E40AF
- Primary/900: #1E3A5F

Color/Neutral:
- Neutral/100: #F3F4F6
- Neutral/300: #D1D5DB
- Neutral/500: #6B7280
- Neutral/700: #374151
- Neutral/900: #111827

Semantic:
- text/default → Neutral/900
- text/subtle → Neutral/500
- bg/default → #FFFFFF
- brand/default → Primary/500

JSON만 반환.
```

---

## 2.8 토큰 파일 구조 설계

프로젝트가 커지면 토큰을 여러 파일로 분리하는 것이 관리에 좋습니다.

### 권장 폴더 구조

```
tokens/
├── base/
│   ├── color.json          # 기본 컬러 스케일
│   ├── typography.json     # 폰트 관련
│   └── spacing.json        # 간격, 크기
├── semantic/
│   ├── light.json          # 라이트 모드 시맨틱
│   └── dark.json           # 다크 모드 시맨틱
└── component/
    ├── button.json         # 버튼 전용 토큰
    └── form.json           # 폼 전용 토큰
```

이 구조를 Copilot에게 설명하면 일관성 있게 파일들을 만들어줍니다:

```
위 tokens/ 폴더 구조에서 component/button.json을 만들어줘.

버튼 전용 토큰:
- 색상은 semantic 토큰 참조 ({color.semantic.brand.default} 형식)
- bg.primary, bg.primary.hover, bg.primary.active
- text.primary, text.secondary
- border.default, border.focus
- 패딩, 폰트 크기는 각 size(sm/md/lg)별로

JSON 형식.
```

---

## 실습

### 실습: 브랜드 컬러 팔레트 → 완전한 토큰 세트

**목표**: 아래 브랜드 팔레트를 받아서 실무에서 바로 쓸 수 있는 토큰 세트를 만듭니다.

**브랜드 정보**

```
회사: 핀테크 스타트업 "FinFlow"
Primary: #0EA5E9 (스카이 블루)
Secondary: #8B5CF6 (바이올렛)
Success: #10B981 (에메랄드)
Warning: #F59E0B (앰버)
Error: #EF4444 (빨강)
Neutral: #64748B (슬레이트)
```

**단계 1. 기본 컬러 스케일 생성** (Chat 사이드바)

```
FinFlow 디자인 시스템의 기본 컬러 토큰 JSON을 만들어줘.

색상:
- primary: #0EA5E9 기준 50~900 스케일
- secondary: #8B5CF6 기준 50~900 스케일
- success: #10B981 기준 100/300/500/700
- warning: #F59E0B 기준 100/300/500/700
- error: #EF4444 기준 100/300/500/700
- neutral: #64748B 기준 50~900 스케일

W3C DTCG JSON 포맷. JSON만.
```

결과를 `tokens/base/color.json`으로 저장.

**단계 2. 시맨틱 토큰 생성**

```
위 base color 토큰을 기반으로 semantic 토큰을 만들어줘.

라이트 모드 시맨틱:
- text: primary / secondary / disabled / inverse / error / success
- bg: default(#FFFFFF) / subtle / emphasis / brand / brand-subtle
- border: default / strong / brand / error
- brand: default / hover / active / subtle
- feedback: error/warning/success/info 각각 bg/text/border

참조 형식 사용. JSON만.
```

결과를 `tokens/semantic/light.json`으로 저장.

**단계 3. 다크 모드 생성**

```
light.json 내용을 다크모드 버전으로 변환해줘.

다크모드 기준:
- bg.default: #0C1929 (네이비 블랙)
- 텍스트는 WCAG AA (4.5:1) 이상 보장
- 브랜드 컬러는 primary.300~400 밝게 조정

JSON만.
```

결과를 `tokens/semantic/dark.json`으로 저장.

**단계 4. CSS Variables 변환**

```
light.json과 dark.json을 CSS custom properties로 변환해줘.
:root (라이트), @media prefers-color-scheme: dark,
[data-theme="dark"] 모두 포함.
CSS만.
```

결과를 `tokens/tokens.css`로 저장.

**완성 체크**

- [ ] `tokens/base/color.json` 생성됨
- [ ] `tokens/semantic/light.json` 생성됨
- [ ] `tokens/semantic/dark.json` 생성됨
- [ ] `tokens/tokens.css` 생성됨
- [ ] CSS 파일을 HTML에 `<link>`로 연결해서 VS Code에서 확인

---

## 핵심 포인트

1. **2계층 구조**: 기본 토큰(실제 값) + 시맨틱 토큰(역할 참조) — 다크모드의 핵심
2. **W3C DTCG 포맷**: `$type`, `$value`, `$description` 키 — 도구 간 호환성
3. **다크모드**: 시맨틱 토큰의 참조 대상만 바꾸면 됨 — 컴포넌트는 건드리지 않음
4. **Copilot 활용**: 스케일 생성, 시맨틱 레이어, CSS 변환 모두 Copilot이 빠름
5. **파일 분리**: base / semantic / component 3레벨로 나눠야 유지보수가 쉬움

---

**다음 문서**: [03-css-basics-for-designers.md](./03-css-basics-for-designers.md) — 디자이너를 위한 CSS 최소 지식
