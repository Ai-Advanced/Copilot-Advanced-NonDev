# 디자이너 Copilot 프롬프트 치트시트

> 복사해서 바로 붙여넣을 수 있는 프롬프트 모음입니다.
> `[대괄호]` 부분만 실제 값으로 교체하세요.

---

## 1. 디자인 토큰

### 1-1. 브랜드 컬러 → 토큰 세트 생성

```
다음 브랜드 컬러를 기반으로 W3C DTCG 포맷 디자인 토큰 JSON을 만들어줘.

Primary: #2563EB
Secondary: #7C3AED
Neutral: #6B7280

포함할 것:
- primary: 50/100/200/300/400/500(기준)/600/700/800/900 스케일
- secondary: 같은 스케일
- neutral: 같은 스케일
- semantic: brand, text-primary, text-secondary, bg-default, bg-subtle, border-default
- 각 토큰은 $type: "color", $value: hex 형식

JSON만 반환.
```

### 1-2. 다크모드 토큰 세트 생성

```
아래 라이트모드 시맨틱 토큰을 기반으로 다크모드 버전을 만들어줘.

라이트모드:
- text-primary: #111827
- text-secondary: #6B7280
- bg-default: #FFFFFF
- bg-subtle: #F9FAFB
- border-default: #E5E7EB
- brand-default: #2563EB

다크모드 요구사항:
- 배경은 #0F172A 기준으로 계층을 만들 것
- 텍스트는 WCAG AA 대비 최소 4.5:1 보장
- brand 색상은 라이트모드보다 10~20% 밝게 조정
- 같은 W3C DTCG JSON 포맷

JSON만 반환.
```

### 1-3. 타이포그래피 토큰 생성

```
타이포그래피 디자인 토큰 JSON을 만들어줘.

폰트 패밀리:
- sans: "Pretendard, -apple-system, sans-serif"
- mono: "JetBrains Mono, monospace"

스케일 (이름 / 크기 / 줄높이 / 자간):
- xs:   12px / 1.5 / 0
- sm:   14px / 1.5 / 0
- base: 16px / 1.6 / 0
- lg:   18px / 1.5 / -0.01em
- xl:   20px / 1.4 / -0.01em
- 2xl:  24px / 1.3 / -0.02em
- 3xl:  30px / 1.2 / -0.02em
- 4xl:  36px / 1.1 / -0.03em

fontWeight 토큰: regular(400), medium(500), semibold(600), bold(700)

W3C DTCG JSON 포맷, JSON만 반환.
```

### 1-4. 간격(Spacing) 토큰 생성

```
4px 베이스의 spacing 토큰 JSON을 만들어줘.

스케일: 0(0px), 1(4px), 2(8px), 3(12px), 4(16px), 5(20px), 6(24px), 8(32px), 10(40px), 12(48px), 16(64px), 20(80px), 24(96px)

추가로:
- borderRadius: none(0), sm(4px), md(8px), lg(12px), xl(16px), 2xl(24px), full(9999px)
- shadow: sm / md / lg / xl (box-shadow 값 포함)
- border: thin(1px), medium(2px), thick(4px)

W3C DTCG JSON 포맷.
```

### 1-5. 기존 토큰 확장 (새 색상 계열 추가)

```
아래 토큰 파일에 success / warning / error / info 시맨틱 색상 계열을 추가해줘.

[현재 tokens.json 파일 내용 붙여넣기]

추가 요구사항:
- success: 초록 계열, #16A34A 기준
- warning: 주황 계열, #D97706 기준
- error: 빨강 계열, #DC2626 기준
- info: 파랑 계열, #2563EB 기준
- 각각 light / default / dark 3단계
- 라이트/다크모드 모두 WCAG AA 대비 유지

기존 구조 유지, 추가 부분만 보여줘.
```

### 1-6. Style Dictionary CSS 변수로 변환

```
아래 디자인 토큰 JSON을 CSS custom properties (CSS 변수)로 변환해줘.

[tokens.json 내용 붙여넣기]

요구사항:
- :root { } 안에 모든 토큰
- 변수명 형식: --token-카테고리-이름 (예: --token-color-primary-500)
- 다크모드는 @media (prefers-color-scheme: dark) { :root { } } 로 분리
- 주석으로 섹션 구분

CSS만 반환.
```

### 1-7. Figma Variables 형식으로 정리

```
아래 디자인 토큰을 Figma Variables 가져오기용 JSON 형식으로 변환해줘.

[tokens.json 내용 붙여넣기]

Figma Variables JSON 구조:
- collections 배열
- 각 collection에 modes (Light, Dark)
- variableCollections 형식 맞출 것

Figma 2024 Variables JSON 포맷 기준.
```

---

## 2. CSS 컴포넌트

### 2-1. 카드 컴포넌트 CSS

```
아래 디자인 스펙을 CSS로 만들어줘.

카드 컴포넌트:
- 너비: 320px (최대), 반응형으로 100% 축소
- 패딩: 24px
- 배경: #FFFFFF
- 테두리: 1px solid #E5E7EB
- 모서리: 12px
- 그림자: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)
- hover 시: 그림자 강해지고, translateY(-2px) 애니메이션
- transition: 200ms ease

내부 구조:
- .card-image: 16:9 비율, object-fit: cover, 상단 모서리 둥글게
- .card-body: 16px 패딩
- .card-title: font-size 18px, font-weight 600, color #111827
- .card-description: font-size 14px, color #6B7280, margin-top 8px
- .card-footer: border-top 1px, padding-top 16px, flex 정렬

CSS variables 사용, 완전한 코드.
```

### 2-2. 버튼 시스템 CSS

```
버튼 컴포넌트 CSS를 만들어줘.

기본 클래스: .btn
- padding: 8px 16px
- border-radius: 8px
- font-weight: 500
- font-size: 14px
- cursor: pointer
- transition: all 150ms ease
- display: inline-flex, align-items: center, gap: 8px

Variants (.btn-primary / .btn-secondary / .btn-ghost / .btn-danger):
- primary: bg #2563EB, text white, hover #1D4ED8
- secondary: bg #F3F4F6, text #374151, hover #E5E7EB
- ghost: bg transparent, text #2563EB, border 1px solid #2563EB
- danger: bg #DC2626, text white, hover #B91C1C

Sizes (.btn-sm / .btn-md / .btn-lg):
- sm: 6px 12px, font 12px
- md: 기본값
- lg: 12px 24px, font 16px

States:
- :disabled 스타일 (opacity 0.5, cursor not-allowed)
- :focus-visible 링 스타일 (접근성)

CSS variables로 색상 관리. 완전한 코드.
```

### 2-3. 내비게이션 바 CSS

```
반응형 내비게이션 바 CSS를 만들어줘.

데스크탑 (768px 이상):
- 높이 64px, 가로 전체
- 배경: #FFFFFF, 하단 border 1px solid #E5E7EB
- position: sticky, top: 0, z-index: 100
- 내부: logo 왼쪽, nav 링크 중앙, CTA 버튼 오른쪽
- nav 링크: 14px, color #374151, hover color #111827, active에 하단 border 2px #2563EB

모바일 (768px 미만):
- 햄버거 메뉴 버튼 표시
- nav는 숨김 → .is-open 클래스 시 전체 너비 드롭다운으로 표시
- 각 링크 16px, padding 12px 16px

backdrop-filter: blur(8px) 옵션 포함. CSS만.
```

### 2-4. 폼 요소 CSS

```
폼 입력 요소 CSS를 만들어줘.

.form-group: margin-bottom 20px

.form-label:
- font-size 14px, font-weight 500, color #374151
- margin-bottom 6px, display block

.form-input (input, textarea, select):
- 너비 100%
- padding: 10px 12px
- border: 1px solid #D1D5DB
- border-radius: 8px
- font-size: 14px, color: #111827
- placeholder color: #9CA3AF
- focus: border-color #2563EB, box-shadow 0 0 0 3px rgba(37,99,235,0.1)
- error 상태(.is-error): border-color #DC2626
- disabled 상태: bg #F9FAFB, cursor not-allowed

.form-hint: font-size 12px, color #6B7280, margin-top 4px
.form-error: font-size 12px, color #DC2626, margin-top 4px

완전한 CSS.
```

### 2-5. 그리드 레이아웃 CSS

```
CSS Grid 기반 반응형 레이아웃 시스템을 만들어줘.

컨테이너:
- .container: max-width 1200px, margin 0 auto, padding 0 24px
- .container-narrow: max-width 768px

그리드:
- .grid: display grid, gap 24px
- .grid-2: 2열 (모바일: 1열)
- .grid-3: 3열 (태블릿: 2열, 모바일: 1열)
- .grid-4: 4열 (태블릿: 2열, 모바일: 1열)

컬럼 span:
- .col-span-2: grid-column span 2
- .col-span-3: grid-column span 3
- .col-full: grid-column 1 / -1

브레이크포인트:
- 모바일: < 640px
- 태블릿: 640px ~ 1024px
- 데스크탑: > 1024px

미디어 쿼리 포함, 완전한 CSS.
```

---

## 3. 반응형 & 애니메이션

### 3-1. 반응형 변환

```
아래 CSS를 모바일 퍼스트 반응형으로 수정해줘.

[현재 CSS 붙여넣기]

브레이크포인트:
- 기본 (모바일): < 640px
- sm: 640px+
- md: 768px+
- lg: 1024px+
- xl: 1280px+

수정 방향:
- 모바일: 1열, 패딩 16px, 폰트 크기 약간 줄임
- 태블릿: 2열 또는 레이아웃 조정
- 데스크탑: 원래 디자인
- touch target 최소 44px 확보

변경된 부분에 주석 추가. 완전한 CSS.
```

### 3-2. 페이드 인 애니메이션

```
스크롤 진입 시 요소가 나타나는 CSS 애니메이션을 만들어줘.

애니메이션 종류:
1. fade-up: 아래에서 위로 올라오며 투명→불투명 (translateY 20px → 0)
2. fade-in: 제자리에서 투명→불투명
3. slide-right: 왼쪽에서 오른쪽으로 (translateX -20px → 0)

공통:
- duration: 400ms
- easing: cubic-bezier(0.16, 1, 0.3, 1)
- 초기 상태: .animate-hidden (opacity 0, transform 적용)
- 활성 상태: .animate-visible (opacity 1, transform none)

JavaScript Intersection Observer와 함께 쓰는 간단한 예시도 포함.
```

### 3-3. 마이크로인터랙션

```
아래 요소들의 마이크로인터랙션 CSS를 만들어줘.

1. 버튼 클릭: scale(0.97) 100ms, 다시 scale(1) 100ms
2. 카드 hover: translateY(-4px), 그림자 강화, 200ms ease
3. 링크 underline: width 0 → 100% 슬라이드 애니메이션, hover 시
4. 입력 포커스: border 컬러 전환 + 좌측에 3px 컬러 바 나타남
5. 토글 스위치: 배경 컬러 + 원 이동 애니메이션 (체크박스 커스텀)
6. 로딩 스피너: 회전 애니메이션, 기본 크기 20px

모두 prefers-reduced-motion 미디어 쿼리도 포함 (접근성).
```

### 3-4. 다크모드 CSS 전환

```
아래 CSS를 다크모드 지원으로 확장해줘.

[현재 CSS 붙여넣기]

방법: CSS custom properties + @media (prefers-color-scheme: dark)

라이트 모드 기준값:
- --bg-default: #FFFFFF
- --bg-subtle: #F9FAFB
- --text-primary: #111827
- --text-secondary: #6B7280
- --border: #E5E7EB
- --brand: #2563EB

다크 모드 대응값:
- --bg-default: #0F172A
- --bg-subtle: #1E293B
- --text-primary: #F1F5F9
- --text-secondary: #94A3B8
- --border: #334155
- --brand: #60A5FA

data-theme="dark" 클래스로도 토글 가능하도록.
```

---

## 4. 접근성 (Accessibility)

### 4-1. 색 대비 검토 요청

```
아래 색상 조합들의 WCAG 2.1 대비율을 계산하고 AA/AAA 기준 통과 여부를 알려줘.

조합 목록:
1. 텍스트 #374151 / 배경 #FFFFFF
2. 텍스트 #6B7280 / 배경 #FFFFFF
3. 텍스트 #FFFFFF / 배경 #2563EB
4. 텍스트 #FFFFFF / 배경 #6B7280
5. 텍스트 #111827 / 배경 #F9FAFB
6. 플레이스홀더 #9CA3AF / 배경 #FFFFFF

기준:
- AA 일반 텍스트: 4.5:1
- AA 큰 텍스트 (18px+ 또는 14px bold+): 3:1
- AAA: 7:1

표 형식으로 결과 정리. 실패한 것은 대안 색상도 제안.
```

### 4-2. HTML 접근성 감사

```
아래 HTML 코드의 접근성 문제를 찾고 수정해줘.

[HTML 코드 붙여넣기]

검토 항목:
- img에 alt 텍스트 누락
- form label-input 연결 (for/id)
- 버튼 aria-label (아이콘만 있는 경우)
- 헤딩 계층 구조 (h1 → h2 → h3 순서)
- 링크 텍스트 ("여기 클릭" 금지)
- 포커스 순서 논리적인가
- role, aria-expanded, aria-hidden 적절히 사용됐는가

문제 목록 표로 정리 후, 수정된 HTML 제공.
```

### 4-3. ARIA 레이블 추가

```
아래 HTML에 ARIA 속성을 추가해줘.

[HTML 코드 붙여넣기]

추가할 ARIA:
- 모달: role="dialog", aria-modal="true", aria-labelledby
- 내비게이션: role="navigation", aria-label
- 드롭다운 메뉴: aria-haspopup, aria-expanded, aria-controls
- 알림/토스트: role="alert" 또는 role="status", aria-live
- 아이콘 버튼: aria-label
- 탭 UI: role="tablist", role="tab", aria-selected, role="tabpanel", aria-labelledby

변경 부분에 주석으로 설명 포함.
```

### 4-4. 키보드 내비게이션 확인

```
아래 컴포넌트가 키보드로 완전히 작동하도록 수정해줘.

[컴포넌트 HTML + CSS 붙여넣기]

요구사항:
- Tab으로 포커스 이동 가능
- Enter/Space로 버튼·링크 활성화
- Escape로 모달/드롭다운 닫기
- Arrow keys로 메뉴/탭 이동
- 포커스 시 :focus-visible 링 스타일 명확히 보임 (outline 제거 금지)
- 포커스 트랩: 모달 열려있을 때 외부로 Tab 이동 안 됨

JavaScript 로직도 필요한 경우 포함.
```

### 4-5. 접근성 체크리스트 생성

```
[컴포넌트 이름] 컴포넌트의 WCAG 2.1 AA 접근성 체크리스트를 만들어줘.

다음 카테고리로 나눠서:
1. 인식 가능 (Perceivable): 색 대비, 텍스트 대안, 미디어 대안
2. 운용 가능 (Operable): 키보드 접근, 충분한 시간, 발작 예방
3. 이해 가능 (Understandable): 가독성, 예측 가능, 입력 도움
4. 견고성 (Robust): 보조기술 호환

각 항목마다: 체크 여부 [], 확인 방법, 실패 시 수정 방법

Markdown 표 형식.
```

---

## 5. 컴포넌트 스펙 문서화

### 5-1. 컴포넌트 스펙 전체 문서

```
[컴포넌트 이름] 컴포넌트의 완전한 스펙 문서를 Markdown으로 작성해줘.

포함할 섹션:
1. 개요 (한 줄 설명, 언제 사용하는가, Figma 링크 자리)
2. Props 표 (이름 / 타입 / 기본값 / 필수여부 / 설명)
3. Variants 표 (variant 이름 / 시각적 설명 / 사용 사례)
4. States 표 (상태 / 시각적 변화 / 트리거)
5. 접근성 (ARIA 속성, 키보드 동작, 스크린 리더 발화)
6. 사용 예시 (DO 3가지 / DON'T 3가지)
7. 관련 컴포넌트 링크
8. 변경 이력 (날짜 / 버전 / 변경 내용)

디자이너가 개발자에게 handoff하는 수준의 상세도.
```

### 5-2. Props 테이블 생성

```
아래 컴포넌트 설명에서 Props 테이블을 추출해줘.

[컴포넌트 설명 또는 Figma 메모 붙여넣기]

표 열: 이름 | 타입 | 기본값 | 필수 | 설명

타입 표기:
- 문자열: string
- 숫자: number
- 불리언: boolean
- 열거형: 'value1' | 'value2'
- 함수: () => void

Markdown 표로 정리. 누락된 Props도 예측해서 추가 (표시 포함).
```

### 5-3. Storybook Controls 스펙

```
아래 컴포넌트 Props를 Storybook Controls 설정 형식으로 정리해줘.

[Props 목록 붙여넣기]

각 Props마다:
- control 타입: text / select / boolean / number / color / range
- 옵션 (select인 경우)
- 기본값
- 설명

표 형식으로, 개발자가 Storybook 설정 시 참고할 수 있도록.
```

### 5-4. 컴포넌트 DO/DON'T 가이드

```
[컴포넌트 이름] 컴포넌트의 사용 가이드를 DO/DON'T 형식으로 작성해줘.

각각 5가지씩:

DO (올바른 사용):
- 실제 사용 예시 설명
- 이유 포함

DON'T (잘못된 사용):
- 실수하기 쉬운 패턴
- 왜 잘못됐는지
- 올바른 대안 제시

표 형식, 시각적으로 명확하게.
```

### 5-5. 개발자 Handoff 문서

```
아래 디자인 스펙을 개발자 handoff 문서로 변환해줘.

[Figma 스펙 또는 디자인 설명 붙여넣기]

개발자가 필요한 정보:
1. 정확한 치수 (px, rem)
2. 색상 값 (hex, CSS variable 이름)
3. 타이포그래피 (font-family, size, weight, line-height, letter-spacing)
4. 간격 (margin, padding, gap)
5. 애니메이션 (duration, easing, 트리거)
6. 상태별 변화 (hover, focus, active, disabled)
7. 반응형 브레이크포인트별 변화
8. 구현 주의사항

Markdown 표 + 코드 블록 혼합. 누락된 값은 "[미정]"으로 표시.
```

---

## 6. HTML 프로토타입

### 6-1. 랜딩 페이지 Hero 섹션

```
랜딩 페이지 Hero 섹션 HTML/CSS를 만들어줘.

레이아웃: 2단 (텍스트 왼쪽, 이미지/일러스트 오른쪽)
모바일: 1단, 이미지 아래로

텍스트 영역:
- 태그라인: font-size 14px, 대문자, letter-spacing 0.1em, 브랜드 컬러
- 헤드라인: font-size 48px (모바일 32px), font-weight 700
- 서브카피: font-size 18px, color #6B7280, max-width 480px
- CTA 버튼 2개: primary(채워진), secondary(테두리)
- social proof: "1,000+ 팀이 사용 중" 문구 + 아바타 스택 (CSS로)

이미지 영역:
- 비율 유지되는 placeholder (배경색 + 텍스트)

배경: 흰색 또는 매우 연한 그라디언트
완전한 HTML + CSS. Live Server로 바로 확인 가능.
```

### 6-2. 피처 섹션

```
SaaS 랜딩 피처 섹션 HTML/CSS를 만들어줘.

레이아웃: 3열 그리드, 각 카드에 아이콘 + 제목 + 설명
모바일: 1열, 태블릿: 2열

각 카드:
- 아이콘 영역: 48x48px, 배경 브랜드 컬러 10% 불투명, 아이콘은 텍스트 이모지로 대체
- 제목: font-size 18px, font-weight 600
- 설명: font-size 14px, color #6B7280, line-height 1.6

섹션 전체:
- 상단에 섹션 태그라인 + 섹션 제목 + 서브카피 (중앙 정렬)
- 배경: #F9FAFB

피처 6개 예시 내용 포함. 완전한 코드.
```

### 6-3. 가격표 섹션

```
SaaS 가격표 섹션 HTML/CSS를 만들어줘.

플랜 3개: Free / Pro / Enterprise
레이아웃: 3열 카드, Pro 카드는 "가장 인기" 배지 + 약간 더 큰 크기

각 카드:
- 플랜 이름, 설명 한 줄
- 가격: 큰 폰트 (30px), "/ 월" 작은 폰트
- 기능 목록: 체크 아이콘 (✓) + 텍스트, 없는 기능은 흐리게
- CTA 버튼

Pro 카드 강조:
- border 2px 브랜드 컬러
- 배경 약간 다른 색
- 배지 CSS로 구현

모바일 반응형 포함. 완전한 코드.
```

### 6-4. 모달/다이얼로그

```
접근성을 갖춘 모달 다이얼로그 HTML/CSS/JS를 만들어줘.

구조:
- .modal-overlay: 반투명 배경 (rgba(0,0,0,0.5))
- .modal: 흰 카드, max-width 480px, 중앙 정렬
- .modal-header: 제목 + 닫기 버튼 (X)
- .modal-body: 스크롤 가능
- .modal-footer: 버튼 2개 (취소 / 확인)

접근성:
- role="dialog", aria-modal="true", aria-labelledby
- 열릴 때 첫 포커스 가능한 요소로 포커스 이동
- Escape 키로 닫기
- 포커스 트랩 (Tab이 모달 내부에서만 순환)
- 배경 스크롤 방지

애니메이션: 배경 fade, 모달 scale + fade (300ms)
```

---

## 7. 문서화 & 핸드오프

### 7-1. 디자인 시스템 README

```
디자인 시스템 README.md를 작성해줘.

시스템 이름: [시스템 이름]
버전: [버전]

포함할 섹션:
1. 개요 (디자인 시스템의 목적, 원칙 3가지)
2. 시작하기 (설치/연결 방법, Figma 라이브러리 링크)
3. 토큰 사용법 (CSS variables 예시, JSON 가져오기)
4. 컴포넌트 목록 (표: 이름 / 상태(완성/진행중/계획) / Figma 링크 / 코드 링크)
5. 기여 방법 (새 컴포넌트 제안, 버그 리포트)
6. 변경 이력 (CHANGELOG 링크)

전문적이지만 접근하기 쉬운 톤.
```

### 7-2. 릴리즈 노트 작성

```
디자인 시스템 v[버전] 릴리즈 노트를 작성해줘.

변경 사항:
[변경 사항 나열]

섹션 구성:
- 🎉 새 컴포넌트
- 🔧 개선 사항
- 🐛 버그 수정
- ⚠️ Breaking Changes (있는 경우)
- 🗑️ Deprecated (있는 경우)

각 항목:
- 컴포넌트/토큰 이름
- 변경 내용 (한 문장)
- 마이그레이션 방법 (Breaking Change인 경우)

Markdown 형식, 개발자와 디자이너 모두 읽는 독자 기준.
```

### 7-3. 컴포넌트 변경 이력

```
아래 컴포넌트의 변경 이력 테이블을 만들어줘.

[변경 사항 나열]

표 열: 날짜 | 버전 | 변경 유형 | 설명 | 담당자

변경 유형:
- Added: 새 기능/props/variants
- Changed: 기존 변경
- Fixed: 버그 수정
- Deprecated: 곧 제거될 것
- Removed: 제거됨

최신 순으로 정렬. Markdown 표.
```

### 7-4. 디자인 QA 체크리스트

```
[기능명] 화면의 디자인 QA 체크리스트를 만들어줘.

카테고리:
1. 레이아웃 (간격, 정렬, 그리드)
2. 타이포그래피 (폰트, 크기, 굵기, 줄높이)
3. 색상 (브랜드 컬러 사용, 상태 색상)
4. 컴포넌트 (디자인 시스템 컴포넌트 사용 여부)
5. 반응형 (모바일 640px, 태블릿 768px, 데스크탑 1280px)
6. 상태 (hover, focus, active, disabled, loading, empty, error)
7. 접근성 (대비, 텍스트 크기, 포커스)
8. 에셋 (이미지 해상도, 아이콘 일관성)

각 항목: [ ] 체크박스 + 확인 포인트 한 줄

총 30~40개 항목.
```

### 7-5. 카피라이팅 배리에이션 생성

```
아래 UI 카피의 배리에이션 5개를 만들어줘.

원본: [카피 텍스트]
용도: [어디에 사용되는가]
타겟: [사용자 페르소나]

배리에이션 방향:
1. 짧게 (원본의 60% 이하)
2. 친근하게 (캐주얼 톤)
3. 전문적으로 (비즈니스 톤)
4. 액션 중심 (동사로 시작)
5. 혜택 중심 (사용자 이득 강조)

각 배리에이션 옆에 한 줄 설명.
```

---

## BAD vs GOOD 프롬프트 비교

### 디자인 토큰

| 구분 | 프롬프트 |
|------|----------|
| ❌ BAD | "디자인 토큰 만들어줘" |
| ✅ GOOD | "Primary #2563EB 기준 10단계 컬러 스케일 + semantic 토큰 (text/bg/border/brand) W3C DTCG JSON 포맷으로. 다크모드 포함. JSON만 반환." |

### CSS 변환

| 구분 | 프롬프트 |
|------|----------|
| ❌ BAD | "이 디자인 CSS로 만들어줘" |
| ✅ GOOD | "카드 컴포넌트 CSS: 배경 #FFF, 패딩 24px, border-radius 12px, 그림자 0 1px 3px rgba(0,0,0,0.1), hover 시 translateY(-2px) 200ms ease. CSS variables 사용. 완전한 코드." |

### 접근성 검토

| 구분 | 프롬프트 |
|------|----------|
| ❌ BAD | "접근성 검토해줘" |
| ✅ GOOD | "아래 HTML의 WCAG 2.1 AA 위반 항목을 찾아 표로 정리하고, 수정된 HTML을 제공해줘. 특히 색 대비, ARIA, 키보드 접근, 폼 레이블 확인. [HTML 붙여넣기]" |

### 프로토타입

| 구분 | 프롬프트 |
|------|----------|
| ❌ BAD | "랜딩 페이지 만들어줘" |
| ✅ GOOD | "SaaS 랜딩 페이지 Hero 섹션 HTML/CSS: 2단 레이아웃, 헤드라인 48px/bold, CTA 버튼 2개(primary/secondary), 배경 흰색. 모바일 반응형 포함. Live Server로 바로 열 수 있게. 완전한 코드." |

### 문서화

| 구분 | 프롬프트 |
|------|----------|
| ❌ BAD | "버튼 스펙 문서 써줘" |
| ✅ GOOD | "Button 컴포넌트 스펙 Markdown 문서: Props 표(이름/타입/기본값/필수/설명), Variants 표(primary/secondary/ghost/danger), States 표(default/hover/focus/disabled), ARIA 속성, 키보드 동작, DO/DON'T 5가지씩. 개발자 handoff 수준." |

---

**관련 문서**: [cheatsheet.md](./cheatsheet.md) | [README.md](./README.md)
