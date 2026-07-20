# 디자이너 Copilot 치트시트

> 이 페이지를 인쇄하거나 모니터 옆에 붙여두세요.

---

## Copilot 3가지 사용 방법

| 방법 | 단축키 | 언제 쓰나 |
|------|--------|----------|
| **Tab 자동완성** | 자동 표시 → Tab | 토큰 값, CSS 속성, 반복 패턴 |
| **Inline Chat** | `Ctrl+I` | 지금 보고 있는 파일 일부 수정 |
| **Chat 사이드바** | `Ctrl+Alt+I` | 새 파일 생성, 긴 대화형 작업 |

---

## 디자이너 업무별 Copilot 활용

| 업무 | 파일 형식 | 핵심 프롬프트 키워드 |
|------|-----------|---------------------|
| 디자인 토큰 | `.json` | "W3C DTCG 포맷", "CSS variables로 변환" |
| CSS 컴포넌트 | `.css` | "완전한 코드", "CSS variables 사용" |
| HTML 프로토타입 | `.html` | "Live Server 호환", "반응형 포함" |
| 컴포넌트 스펙 | `.md` | "Props 표", "DO/DON'T" |
| 접근성 검토 | `.html` | "WCAG 2.1 AA", "수정된 HTML 제공" |
| 다크모드 | `.css` | "@media prefers-color-scheme: dark" |

---

## 황금 프롬프트 공식

```
[결과물 형식] + [구체적 스펙] + [CSS 방법론] + "완전한 코드"
```

**예시**:
```
카드 컴포넌트 CSS:
- 패딩 24px, border-radius 12px
- hover 시 translateY(-2px) 200ms ease
- CSS variables 사용
완전한 코드.
```

---

## BAD vs GOOD 한눈에

| ❌ BAD | ✅ GOOD |
|--------|---------|
| "디자인 토큰 만들어줘" | "Primary #2563EB → 10단계 스케일 + semantic 토큰, W3C DTCG JSON, 다크모드 포함" |
| "CSS로 만들어줘" | "카드 컴포넌트 CSS: 패딩 24px, 그림자 0 1px 3px rgba(0,0,0,0.1), hover 애니메이션 200ms" |
| "접근성 확인해줘" | "아래 HTML WCAG 2.1 AA 위반 찾아 표로 정리 후 수정된 HTML 제공" |
| "랜딩 페이지 만들어줘" | "Hero 섹션: 2단, 헤드라인 48px, CTA 2개, 반응형, Live Server 호환, 완전한 코드" |

---

## 디자인 토큰 빠른 공식

```json
{
  "color": {
    "primary": {
      "500": { "$type": "color", "$value": "#2563EB" }
    }
  }
}
```

CSS Variables 변환:
```css
:root {
  --color-primary-500: #2563EB;
}
@media (prefers-color-scheme: dark) {
  :root { --color-primary-500: #60A5FA; }
}
```

---

## WCAG 2.1 AA 대비율 기준

| 텍스트 종류 | 최소 대비율 |
|-------------|------------|
| 일반 텍스트 (< 18px) | **4.5 : 1** |
| 큰 텍스트 (18px+ 또는 14px bold+) | **3 : 1** |
| UI 컴포넌트 / 그래픽 | **3 : 1** |
| AAA 기준 (선택) | 7 : 1 |

자주 쓰는 조합 결과:
- `#374151` / `#FFFFFF` → **10.7:1** ✅
- `#6B7280` / `#FFFFFF` → **4.6:1** ✅
- `#9CA3AF` / `#FFFFFF` → **2.8:1** ❌ (플레이스홀더 주의)
- `#FFFFFF` / `#2563EB` → **7.6:1** ✅

---

## CSS 브레이크포인트 표준

```css
/* 모바일 퍼스트 */
/* 기본: 모바일 (<640px) */
@media (min-width: 640px)  { /* sm: 태블릿+ */ }
@media (min-width: 768px)  { /* md */ }
@media (min-width: 1024px) { /* lg: 데스크탑+ */ }
@media (min-width: 1280px) { /* xl */ }
```

---

## 기억할 것

1. **Figma = 시각 디자인 도구, Copilot = 문서/코드/토큰 도구** (대체 관계 아님)
2. **AI 결과는 반드시 브라우저에서 확인** (Live Server 필수)
3. **색 대비는 반드시 계산기로 검증** (Copilot 계산 100% 신뢰 금지)
4. **프롬프트에 "완전한 코드"** 붙이면 중간에 자르지 않음
5. **접근성은 마지막이 아니라 처음부터** — 나중에 고치면 2배 힘듦

---

**전체 프롬프트 목록**: [prompts.md](./prompts.md)
**커리큘럼 시작**: [day1/01-designer-copilot-overview.md](./day1/01-designer-copilot-overview.md)
