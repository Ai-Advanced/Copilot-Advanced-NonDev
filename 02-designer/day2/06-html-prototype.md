# 06. HTML/CSS 클릭 가능 프로토타입

## 학습 목표

- VS Code + Live Server로 브라우저에서 바로 확인하는 HTML 프로토타입 환경 구축
- Copilot으로 반응형 레이아웃과 CSS 애니메이션 프롬프팅
- Figma 프로토타입 대비 HTML 프로토타입의 강점 이해
- 실습: 랜딩 페이지 Hero + Feature + Footer 완성

**예상 소요**: 70분

---

## 6.1 HTML 프로토타입이 필요한 이유

Figma 프로토타입으로 충분하지 않을 때가 있습니다.

| 상황 | Figma 프로토타입 | HTML 프로토타입 |
|------|-----------------|----------------|
| 링크 클릭 이동 | ✅ | ✅ |
| CSS 애니메이션 (hover, scroll) | ❌ | ✅ |
| 실제 반응형 동작 | ❌ (고정 프레임) | ✅ |
| 폼 입력 테스트 | ❌ | ✅ |
| 이해관계자 공유 (링크) | Figma 계정 필요 | URL 공유 or 파일 전달 |
| 개발팀에 "이런 느낌" 전달 | 해석 오차 있음 | CSS 코드가 곧 스펙 |

**HTML 프로토타입의 한계**: Figma처럼 디자인을 *만드는* 도구는 아닙니다. Figma에서 완성한 디자인을 *검증하고 전달*하는 용도입니다.

---

## 6.2 Live Server 설정

### 설치 확인

VS Code 확장에서 "Live Server" 검색 → Ritwick Dey 제작 버전 설치.

### 사용법

1. `.html` 파일 오른쪽 클릭 → **"Open with Live Server"**
2. 브라우저가 자동으로 열림 (`http://127.0.0.1:5500/...`)
3. 파일 저장할 때마다 브라우저 **자동 새로고침**

### HTML 파일 기본 구조

Copilot에게 새 프로토타입을 요청할 때 항상 이 구조를 지정:

```
새 랜딩 페이지 HTML 파일 기본 구조를 만들어줘.

요구사항:
- <!DOCTYPE html>, lang="ko"
- meta charset, viewport (반응형 필수)
- title, description meta
- Google Fonts 연결: Pretendard (없으면 system-ui 폴백)
- 외부 CSS 파일 연결: styles.css
- box-sizing: border-box 전역 설정
- body 기본: font-family, color, background-color 설정

빈 body로 완전한 HTML.
```

결과:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="페이지 설명" />
  <title>페이지 제목</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <!-- 콘텐츠 -->
</body>
</html>
```

---

## 6.3 Hero 섹션 프롬프팅

### 기본 Hero (텍스트 중심)

```
SaaS 랜딩 페이지 Hero 섹션 HTML/CSS를 만들어줘.

레이아웃: 2단 (텍스트 왼쪽 55%, 이미지/일러스트 오른쪽 45%)
모바일(768px 이하): 1단, 이미지 텍스트 아래

텍스트 영역 (위에서 아래 순서):
1. .hero-tag: "✨ 새로운 기능 출시" 배지 스타일 (pill, 배경 #EFF6FF, 색 #2563EB)
2. .hero-headline: "팀의 생산성을 3배로 높이세요" (font-size 52px, bold, line-height 1.15)
   모바일: 32px
3. .hero-subtext: 설명 (18px, color #6B7280, max-width 500px)
   모바일: 16px
4. .hero-cta: 버튼 2개 flex row, gap 16px
   - "무료로 시작하기" (primary, 큰 버튼)
   - "데모 보기" (ghost)
5. .hero-proof: "1,200+ 팀이 이미 사용 중" + 아바타 스택 CSS로 (5개 원형, -8px 겹치게)

이미지 영역:
- .hero-image: aspect-ratio 4/3, 배경 그라디언트 #EFF6FF→#DBEAFE, 둥근 모서리 20px

섹션 전체:
- padding: 80px 0 (데스크탑), 60px 0 (모바일)
- max-width 1200px, margin 0 auto, padding-x 24px

완전한 HTML + CSS (인라인 style 없이, 외부 CSS 블록).
```

### 애니메이션 추가

Hero를 만든 후 Inline Chat(`Ctrl+I`)으로 선택한 CSS에:

```
페이지 로드 시 Hero 요소들이 순서대로 나타나는 CSS 애니메이션 추가.

.hero-tag: 0.1s 딜레이
.hero-headline: 0.2s 딜레이
.hero-subtext: 0.3s 딜레이
.hero-cta: 0.4s 딜레이
.hero-proof: 0.5s 딜레이
.hero-image: 0.3s 딜레이, 오른쪽에서 슬라이드

애니메이션: fade-up (아래에서 20px 올라오며 투명→불투명)
duration: 600ms, easing: cubic-bezier(0.16, 1, 0.3, 1)
prefers-reduced-motion: 애니메이션 없이 바로 표시
```

---

## 6.4 Feature 섹션 프롬프팅

### 3열 피처 카드

```
SaaS 랜딩 피처 섹션 HTML/CSS를 만들어줘.

섹션 상단 (중앙 정렬):
- .features-tag: "핵심 기능" 배지
- .features-title: "작업 방식을 바꾸는 기능들" (36px, bold)
- .features-subtitle: 설명 (18px, color #6B7280, max-width 600px)
- margin-bottom 64px

피처 카드 그리드:
- 3열 (tablet 768px: 2열, mobile 480px: 1열)
- gap 32px

각 .feature-card:
- padding 32px
- border 1px solid #E5E7EB, border-radius 16px
- background white
- hover: border-color #2563EB, box-shadow 0 4px 20px rgba(37,99,235,0.1), transform translateY(-2px)
- transition 200ms ease

카드 내부 (위에서 아래):
1. .feature-icon: 52px 원형, 배경 #EFF6FF, 아이콘은 이모지 텍스트 (32px)
2. .feature-title: 20px, semibold, margin-top 20px
3. .feature-desc: 15px, color #6B7280, line-height 1.65, margin-top 8px

피처 6개 예시 내용 포함:
1. ⚡ 빠른 성능 / 2. 🔒 강력한 보안 / 3. 📊 상세 분석
4. 🤝 팀 협업 / 5. 🔄 자동 동기화 / 6. 🌍 글로벌 지원

배경: #F9FAFB
섹션 패딩: 96px 0
완전한 코드.
```

---

## 6.5 가격표 프롬프팅

```
SaaS 가격표 섹션 HTML/CSS를 만들어줘.

섹션 제목 + 연간/월별 토글 버튼 (CSS만, JS 없이 스타일만):
- 토글: 두 버튼, active 버튼은 배경 브랜드 컬러 + 흰 텍스트

플랜 카드 3개 (Free / Pro / Enterprise):
레이아웃: 3열, Pro 카드가 가운데이며 약간 크게 (scale 또는 패딩 더 크게)
모바일: 1열

각 카드:
- border 2px solid (기본: #E5E7EB, Pro: #2563EB)
- border-radius 20px, padding 32px
- "가장 인기" 배지: Pro 카드 상단에 (배경 #2563EB, 흰 텍스트, 절대 위치)

카드 내부:
- 플랜 이름 (16px, uppercase, letter-spacing 0.08em, 브랜드 컬러)
- 설명 한 줄 (14px, color #6B7280)
- 가격 (월별): 숫자 48px bold + "/월" 16px
- 기능 목록: ✓ 있음 (color #16A34A) / × 없음 (color #9CA3AF)
- CTA 버튼: Free는 ghost, Pro는 primary, Enterprise는 secondary

배경: 흰색
섹션 패딩: 96px 0
완전한 코드.
```

---

## 6.6 Footer 프롬프팅

```
랜딩 페이지 Footer HTML/CSS를 만들어줘.

레이아웃: 4열 그리드 (mobile: 2열 또는 1열)
- 열 1: 로고 + 회사 소개 2줄 + 소셜 아이콘 3개 (SVG 대신 이모지)
- 열 2: 제품 (링크 5개)
- 열 3: 회사 (링크 5개)
- 열 4: 지원 (링크 5개)

하단 바 (border-top, padding 24px 0):
- 왼쪽: ©2026 회사명
- 오른쪽: 개인정보처리방침 · 이용약관

스타일:
- 배경: #0F172A (다크)
- 텍스트: #94A3B8
- 링크 hover: 흰색
- 로고 컬러: 흰색
- 구분선: #1E293B
- 링크 사이 간격: 12px

완전한 HTML + CSS.
```

---

## 6.7 반응형 체크포인트

프로토타입 완성 후 반드시 확인해야 할 체크리스트:

```
위 landing.html의 반응형 동작을 점검하고 수정해줘.

확인할 브레이크포인트:
- 320px (갤럭시 폴드 닫힘): 텍스트 잘림 없는지
- 375px (iPhone SE): 기본 모바일
- 768px (iPad 세로): 태블릿 전환
- 1024px (iPad 가로): 작은 데스크탑
- 1440px (FHD 모니터): 표준 데스크탑

수정이 필요한 경우:
- overflow-x: hidden 없이 가로 스크롤 없어야 함
- 터치 타겟 최소 44x44px
- 텍스트 최소 14px (모바일)
- 이미지 크기 조정

발견된 문제와 수정 CSS를 알려줘.
```

### 브라우저 개발자 도구로 반응형 확인

1. 브라우저에서 `F12` 또는 `Ctrl+Shift+I` → 개발자 도구 열기
2. 상단 디바이스 아이콘 클릭 (또는 `Ctrl+Shift+M`)
3. 상단 드롭다운에서 기기 선택 또는 너비 직접 입력

---

## 실습

### 실습: 랜딩 페이지 Hero + Feature + Footer 완성

**목표**: 브라우저에서 실제로 동작하는 3섹션 랜딩 페이지를 Copilot으로 만듭니다.

**프로젝트 설정**

```
copilot-landing/
├── index.html
└── styles.css
```

**단계 1. HTML 뼈대 (5분)**

`index.html` 파일 생성 후 Chat:

```
SaaS 랜딩 페이지 HTML 뼈대를 만들어줘.

섹션 구성:
1. <header> (나중에 Nav 추가)
2. <section id="hero">
3. <section id="features">
4. <section id="pricing">
5. <footer>

외부 스타일시트: styles.css 연결
CSS 리셋: *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body: font-family "Noto Sans KR", system-ui, sans-serif (Google Fonts 연결)

완전한 HTML 뼈대.
```

**단계 2. CSS 기본 변수 (5분)**

`styles.css` 파일 생성 후 Chat:

```
styles.css의 :root에 CSS variables를 추가해줘.

--color-brand: #2563EB
--color-brand-hover: #1D4ED8
--color-brand-light: #EFF6FF
--color-text-primary: #111827
--color-text-secondary: #6B7280
--color-bg: #FFFFFF
--color-bg-subtle: #F9FAFB
--color-border: #E5E7EB
--font-sans: "Noto Sans KR", system-ui, sans-serif
--radius-sm: 8px
--radius-md: 12px
--radius-lg: 20px
--radius-full: 9999px
--shadow-sm: 0 1px 3px rgba(0,0,0,0.08)
--shadow-md: 0 4px 16px rgba(0,0,0,0.1)
--max-width: 1200px

전체 body 기본 스타일도 포함.
CSS만.
```

**단계 3. 세 섹션 완성 (40분)**

Hero, Feature, Footer를 차례로 추가합니다. 각 섹션은 위의 6.3~6.6 프롬프트를 사용하되, `--color-brand`, `--radius-lg` 같은 CSS variables를 사용하도록 명시합니다.

```
[Hero/Feature/Footer 각 섹션에 대해]
HTML은 index.html의 해당 section에, CSS는 styles.css에 추가.
CSS variables(--color-brand 등) 사용.
완전한 HTML + CSS 코드 블록 2개로 제공.
```

**단계 4. 스크롤 애니메이션 추가 (10분)**

```
styles.css에 스크롤 진입 애니메이션을 추가해줘.

.animate-on-scroll 클래스:
- 초기: opacity 0, translateY 30px
- .is-visible 클래스 추가 시: opacity 1, translateY 0
- duration: 500ms, easing: ease-out

index.html에 있는 feature-card 들에 .animate-on-scroll 클래스 추가.

아래 JS도 추가 (index.html <script> 태그):
Intersection Observer로 화면 진입 시 .is-visible 추가.
prefers-reduced-motion: true면 모든 요소 즉시 visible로.
```

**단계 5. 최종 Live Server 확인**

체크리스트:

- [ ] Hero 섹션 텍스트 + 버튼 + 프루프 표시
- [ ] 페이지 로드 시 Hero 요소 fade-up 애니메이션
- [ ] Feature 카드 6개 3열 그리드
- [ ] Feature 카드 hover 시 테두리 컬러 + 그림자
- [ ] 스크롤 시 Feature 카드 순서대로 나타남
- [ ] Footer 4열 레이아웃
- [ ] 브라우저 창 좁히면 반응형 전환
- [ ] 모바일(375px)에서 가로 스크롤 없음

---

## 핵심 포인트

1. **Live Server**: 저장할 때마다 자동 새로고침 — 실시간 확인 가능
2. **CSS Variables 먼저**: `:root` 변수 정의 후 컴포넌트 작성 — 일관성 보장
3. **섹션별 프롬프트**: 한 번에 전체 페이지보다 섹션별로 요청 — 품질 향상
4. **반응형은 마지막에 확인**: 완성 후 개발자 도구로 여러 화면 크기 체크
5. **애니메이션은 prefers-reduced-motion 포함**: 접근성 필수 요건

---

**다음 문서**: [07-accessibility-and-polish.md](./07-accessibility-and-polish.md) — 접근성 검토와 품질 개선
