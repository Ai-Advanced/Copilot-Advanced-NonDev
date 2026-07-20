# 07. 접근성과 품질 개선

## 학습 목표

- WCAG 2.1 AA 기준의 핵심 요건을 디자이너 관점에서 이해
- 색 대비, ARIA, 키보드 내비게이션을 Copilot으로 점검하고 수정
- 다크모드와 반응형을 기존 프로토타입에 추가하는 방법 습득
- 실습: Day 2 프로토타입 접근성 감사 → 수정

**예상 소요**: 50분

---

## 7.1 왜 접근성인가 — 디자이너의 책임

접근성은 "장애인을 위한 기능"이 아닙니다.

| 접근성 요건 | 혜택을 받는 사람 |
|-------------|----------------|
| 높은 색 대비 | 시각 장애인, 햇빛 아래 폰 사용자, 노인 |
| 큰 터치 타겟 (44px+) | 손이 떨리는 사람, 장갑 낀 사람, 피로한 사람 |
| 키보드 내비게이션 | 마우스 못 쓰는 사람, 파워 유저, 폼 빠른 입력 |
| 명확한 에러 메시지 | 모든 사람 (색만으로 오류 표현하면 색맹에게 안 보임) |
| 자막/텍스트 대안 | 청각 장애인, 소음 환경, 언어 학습자 |

**WCAG 2.1 레벨**

| 레벨 | 의미 | 목표 |
|------|------|------|
| A | 최소 기준 (이것도 못 지키면 사실상 사용 불가) | 반드시 |
| **AA** | **일반적인 산업 표준, 법적 요건 기준** | 이게 목표 |
| AAA | 최상위 (일부 요건은 현실적으로 어려움) | 여유 있을 때 |

---

## 7.2 색 대비 — 숫자로 확인하기

### 대비율 계산

WCAG AA 기준:
- 일반 텍스트 (18px 미만, normal weight): **4.5:1**
- 큰 텍스트 (18px 이상, 또는 14px bold 이상): **3:1**
- UI 컴포넌트 경계선, 그래픽: **3:1**

### Copilot으로 대비율 점검

```
아래 색상 조합들의 WCAG 2.1 대비율을 계산하고 AA/AAA 기준 통과 여부를 알려줘.

조합:
1. 텍스트 #374151 / 배경 #FFFFFF
2. 텍스트 #6B7280 / 배경 #FFFFFF
3. 텍스트 #9CA3AF / 배경 #FFFFFF  (플레이스홀더)
4. 텍스트 #FFFFFF / 배경 #2563EB  (primary 버튼)
5. 텍스트 #FFFFFF / 배경 #6B7280  (secondary 버튼)
6. 텍스트 #1D4ED8 / 배경 #EFF6FF  (링크 on 연파란 배경)
7. 텍스트 #92400E / 배경 #FEF3C7  (warning 알림)
8. 텍스트 #991B1B / 배경 #FEF2F2  (error 알림)

표 형식: 조합 | 대비율 | AA 일반 | AA 큰텍스트 | 비고
실패한 조합은 WCAG AA 통과하는 대안 색상도 제안.
```

> **주의**: Copilot의 대비율 계산은 참고용입니다. 정확한 수치는 반드시 [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) 또는 [Colour Contrast Analyser](https://www.tpgi.com/color-contrast-checker/) 도구로 검증하세요.

### 자주 실패하는 색상

| 색상 | 배경 | 대비율 | 문제 |
|------|------|--------|------|
| `#9CA3AF` (gray-400) | `#FFFFFF` | 2.85:1 | ❌ 플레이스홀더로 자주 씀 |
| `#6EE7B7` (emerald-300) | `#FFFFFF` | 1.97:1 | ❌ success 색으로 쓰면 위험 |
| `#FCD34D` (amber-300) | `#FFFFFF` | 1.58:1 | ❌ 노란 배지 텍스트 |
| `#60A5FA` (blue-400) | `#FFFFFF` | 3.0:1 | ⚠️ 큰 텍스트만 통과 |

---

## 7.3 ARIA — 보이지 않는 의미 전달

ARIA(Accessible Rich Internet Applications)는 HTML만으로 전달하기 어려운 의미를 스크린 리더에게 알려주는 속성입니다.

### 디자이너가 반드시 알아야 할 ARIA 5가지

**1. 아이콘 버튼 — aria-label**

```html
<!-- ❌ BAD: 스크린 리더가 "버튼"이라고만 읽음 -->
<button>
  <svg><!-- 삭제 아이콘 --></svg>
</button>

<!-- ✅ GOOD: "삭제, 버튼"이라고 읽음 -->
<button aria-label="삭제">
  <svg aria-hidden="true"><!-- 삭제 아이콘 --></svg>
</button>
```

**2. 모달 — role="dialog"**

```html
<!-- ✅ -->
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">삭제 확인</h2>
  ...
</div>
```

**3. 드롭다운 메뉴 — aria-expanded**

```html
<!-- ✅ -->
<button aria-haspopup="true" aria-expanded="false" aria-controls="menu">
  메뉴 열기
</button>
<ul id="menu" role="menu" hidden>...</ul>
<!-- JS로 클릭 시 aria-expanded="true", hidden 제거 -->
```

**4. 알림 — role="alert"**

```html
<!-- ✅: 동적으로 추가될 때 스크린 리더가 즉시 읽음 -->
<div role="alert" aria-live="assertive">
  저장에 실패했습니다. 다시 시도해주세요.
</div>

<!-- 덜 급한 알림 -->
<div role="status" aria-live="polite">
  파일이 저장됐습니다.
</div>
```

**5. 폼 레이블 연결**

```html
<!-- ❌ BAD: label이 input과 연결 안 됨 -->
<label>이메일</label>
<input type="email" />

<!-- ✅ GOOD: for-id 연결 -->
<label for="email">이메일</label>
<input type="email" id="email" />
```

### Copilot으로 ARIA 추가

```
아래 HTML에 ARIA 속성을 추가해줘. WCAG 2.1 AA 기준.

[HTML 코드 붙여넣기]

확인 항목:
- 아이콘만 있는 버튼: aria-label 추가
- 내비게이션: aria-label로 구분
- 모달/다이얼로그: role, aria-modal, aria-labelledby
- 폼: label-input 연결 확인
- 이미지: alt 텍스트 (장식 이미지는 alt="")
- 동적 알림: role="alert" 또는 role="status"
- 열기/닫기 버튼: aria-expanded, aria-controls

변경된 줄마다 // ARIA 주석 추가.
수정된 완전한 HTML 반환.
```

---

## 7.4 키보드 내비게이션

모든 인터랙티브 요소는 키보드로 접근 가능해야 합니다.

### 포커스 스타일

```css
/* ❌ 절대 하지 말 것 */
* { outline: none; }  /* 키보드 사용자가 어디 있는지 모름 */

/* ✅ 마우스 클릭 시엔 outline 숨기고, 키보드 Tab 시엔 표시 */
:focus { outline: none; }                   /* 마우스 클릭 포커스 */
:focus-visible {                            /* 키보드 포커스만 */
  outline: 3px solid #2563EB;
  outline-offset: 2px;
  border-radius: 4px;
}
```

### 포커스 트랩 (모달)

모달이 열려 있을 때 Tab이 모달 밖으로 나가면 안 됩니다.

```
아래 모달 HTML에 포커스 트랩 JavaScript를 추가해줘.

[모달 HTML 붙여넣기]

요구사항:
- 모달 열릴 때: 첫 번째 포커스 가능한 요소로 포커스 이동
- Tab: 모달 내 마지막 요소에서 첫 요소로 순환
- Shift+Tab: 모달 내 첫 요소에서 마지막 요소로 역순환
- Escape: 모달 닫기
- 모달 닫힐 때: 모달 열었던 버튼으로 포커스 복귀

vanilla JS만 사용 (라이브러리 없이).
```

---

## 7.5 다크모드 추가

기존 프로토타입에 다크모드를 추가하는 방법입니다.

### CSS Variables 기반 (권장)

Day 1에서 만든 토큰 구조를 이미 쓰고 있다면, 다크모드 추가는 쉽습니다:

```
styles.css에 다크모드 지원을 추가해줘.

현재 :root 변수:
--color-bg: #FFFFFF
--color-text-primary: #111827
--color-text-secondary: #6B7280
--color-border: #E5E7EB
--color-brand: #2563EB
[기타 변수들]

다크모드 변수:
--color-bg: #0F172A
--color-text-primary: #F1F5F9
--color-text-secondary: #94A3B8
--color-border: #334155
--color-brand: #60A5FA (더 밝은 파란색, 대비율 유지)

추가:
1. @media (prefers-color-scheme: dark) { :root { ... } }
2. [data-theme="dark"] { ... }
3. 토글 버튼 JS: document.body.toggleAttribute('data-theme', 'dark') 정도

CSS + JS 모두 반환.
```

### 다크모드 전환 시 주의사항

```
현재 styles.css의 다크모드를 검토하고 문제를 찾아줘.

확인 항목:
- 이미지 오버레이: 다크모드에서 너무 밝은 이미지 문제
  → filter: brightness(0.85) opacity(0.9) 고려
- 그림자: 다크모드에서 box-shadow가 너무 강함
  → rgba 투명도 줄이거나 색조 변경
- 배지/태그: 배경이 너무 밝으면 다크모드에서 어색
  → 각 배지 다크모드 값도 확인

수정이 필요한 것만 알려줘.
```

---

## 7.6 반응형 점검

### 공통 문제와 Copilot 수정 요청

**문제 1. 텍스트가 너무 커서 모바일에서 넘침**

```
hero-headline이 모바일에서 줄 바꿈 없이 화면을 넘쳐요.
모바일(480px 이하) font-size를 clamp() 함수로 조정해줘.
데스크탑 52px, 태블릿 40px, 모바일 28px으로 유동적으로.
```

**문제 2. 버튼이 너무 작아서 탭 하기 어려움**

```
모바일에서 버튼의 touch target이 44px 미만이에요.
.btn-sm의 최소 높이 44px을 보장하되 시각적 크기는 유지하는 방법으로 수정해줘.
(padding 유지하고 min-height: 44px 또는 ::before pseudo로 hit area 확장)
```

**문제 3. 이미지가 모바일에서 너무 큼**

```
.hero-image가 모바일에서 화면 높이의 60%를 차지해요.
모바일에서 max-height: 280px으로 제한하고 aspect-ratio 유지하도록 수정.
```

---

## 실습

### 실습: 프로토타입 접근성 감사 → 수정

**목표**: Day 2 실습에서 만든 `index.html`을 접근성 감사하고 주요 문제를 수정합니다.

**단계 1. 자동 감사 요청**

Chat에:

```
아래 HTML 파일의 WCAG 2.1 AA 접근성 문제를 전체 감사해줘.

[index.html 전체 내용 붙여넣기 — 길면 <section>별로 나눠서]

감사 항목:
1. 이미지 alt 텍스트
2. 폼 label-input 연결
3. 버튼/링크 레이블 (아이콘만 있는 경우)
4. 헤딩 계층 구조 (h1 → h2 → h3 순서)
5. 색 대비 (CSS에서 사용된 색상 확인)
6. aria 속성 적절성
7. 포커스 스타일 (:focus-visible)
8. 키보드 접근 불가한 인터랙티브 요소

결과를 표로 정리:
| 줄번호 | 요소 | 문제 | 심각도(Critical/Major/Minor) | 수정 방법 |
```

**단계 2. Critical 문제 수정**

감사 결과에서 Critical 항목을 먼저 수정:

```
위 감사 결과의 Critical 문제들을 모두 수정한 HTML을 제공해줘.

변경된 부분에 <!-- FIXED: 문제 설명 --> 주석 추가.
완전한 수정된 HTML.
```

**단계 3. 포커스 스타일 추가**

```
styles.css에 키보드 포커스 스타일을 추가해줘.

:focus { outline: none; }
:focus-visible {
  outline: 3px solid var(--color-brand);
  outline-offset: 2px;
  border-radius: 4px;
}

버튼, 링크, 입력 요소 모두 적용.
기존 :focus { outline: none; }이 있으면 교체.
```

**단계 4. 다크모드 토글 추가**

```
index.html에 다크모드 토글 버튼을 추가해줘.

위치: header 우측 끝 (기존 버튼들 옆)
모양: 달 🌙 아이콘 버튼, 다크모드 시 ☀️ 로 변경
JS: localStorage에 테마 저장, 페이지 로드 시 복원

CSS: [data-theme="dark"] body { ... } 필요 변수들 추가
```

**완성 체크**

- [ ] Critical 접근성 문제 0개
- [ ] 모든 아이콘 버튼에 aria-label 있음
- [ ] 키보드 Tab으로 모든 버튼/링크 이동 가능
- [ ] 포커스 시 파란 링 표시
- [ ] 다크모드 토글 작동
- [ ] 다크모드에서 텍스트가 배경과 충분한 대비

---

## 핵심 포인트

1. **대비율 4.5:1**: 일반 텍스트의 최소 기준 — Copilot 계산은 참고용, 도구로 검증 필수
2. **outline: none 금지**: 포커스 스타일 제거는 접근성 위반 — `:focus-visible` 사용
3. **ARIA 5가지**: aria-label (아이콘 버튼), role="dialog", aria-expanded, role="alert", label-for
4. **다크모드**: CSS Variables 구조가 있으면 추가 2분 — 처음부터 변수로 짜야 하는 이유
5. **접근성은 감사가 아니라 설계**: 처음부터 스펙에 포함해야 비용이 낮음

---

**다음 문서**: [08-capstone.md](./08-capstone.md) — 캡스톤 프로젝트: SaaS 대시보드 A~Z
