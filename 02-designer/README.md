# 디자이너를 위한 GitHub Copilot 2일 심화 과정

**과정 후 추가 실습:** [Copilot CLI로 쇼케이스를 Azure에 배포](../09-azure-capstone/README.md) · [직군별 요구사항](../09-azure-capstone/roles.md). 기존 2일 과정 외 별도 편성입니다.

> **대상**: UX/UI 디자이너, 그래픽 디자이너, Figma/Sketch 사용자
> **기간**: 2일 (각 3~4시간, 총 6~8시간)
> **선행 필수**: [00-basics/](../00-basics/) 완료 후 시작

---

## 이 과정이 필요한 이유

디자이너에게 Copilot은 "코딩 도구"가 아닙니다.

Figma에서 완성한 디자인이 개발자 손에 들어가는 순간 생기는 일들, 즉 토큰 문서 정리, 컴포넌트 스펙 작성, 개발자 handoff 자료 만들기, HTML 프로토타입 제작, 접근성 검토... 이 모든 반복적인 문서·코드 작업을 Copilot이 극적으로 단축해줍니다.

> **명확히 해두기**: Copilot은 Figma를 대체하지 않습니다.
> Figma는 시각적 디자인 도구입니다. Copilot은 그 결과물을 **문서화하고, 코드로 변환하고, 개발자에게 전달하는 과정**을 돕는 도구입니다.

| 기존 방식 | Copilot과 함께 |
|-----------|---------------|
| 디자인 토큰을 손으로 JSON 타이핑 | 팔레트 설명 → 완전한 토큰 JSON 자동 생성 |
| 컴포넌트 스펙 표를 워드/노션에서 하나씩 채우기 | 스펙 요약 입력 → Props/State/Variants 표 완성 |
| 개발자에게 CSS 물어보기 | Copilot이 디자인 설명을 CSS로 번역 |
| HTML 프로토타입 = 개발팀에 의뢰 | Copilot으로 클릭 가능한 프로토타입 당일 완성 |
| 접근성 체크 = 외주 감사 | Copilot으로 WCAG 2.1 AA 기준 자가 점검 |

---

## 사전 준비

### 필수 설치

- [ ] VS Code 최신 버전
- [ ] 확장: `GitHub Copilot`
- [ ] 확장: `GitHub Copilot Chat`
- [ ] 확장: `Live Server` (HTML 프로토타입 브라우저 미리보기용)
- [ ] 확장: `Prettier - Code formatter` (코드 정렬)

### 선택 설치

- [ ] 확장: `Color Highlight` (CSS hex 색상 미리보기)
- [ ] 확장: `CSS Peek` (CSS 클래스 확인)
- [ ] 확장: `Auto Rename Tag` (HTML 태그 자동 수정)

### 설치 확인

VS Code를 열고 `Ctrl+Shift+P` → "GitHub Copilot: Check Status" 실행. 초록불이 켜지면 준비 완료.

---

## 학습 목표

2일 과정을 마치면 다음을 할 수 있습니다:

**Day 1 종료 시**
- 디자인 토큰(Color, Typography, Spacing)을 JSON으로 관리하고 Copilot으로 확장할 수 있다
- Flexbox/Grid CSS를 Copilot 도움으로 작성하고 수정할 수 있다
- 브랜드 팔레트에서 완전한 디자인 토큰 세트를 만들 수 있다

**Day 2 종료 시**
- Storybook 스타일의 컴포넌트 스펙 문서를 Copilot으로 완성할 수 있다
- Live Server로 바로 확인 가능한 HTML/CSS 프로토타입을 만들 수 있다
- WCAG 2.1 AA 기준으로 접근성을 점검하고 수정할 수 있다
- 개발자 handoff용 최종 문서를 패키지로 전달할 수 있다

---

## 커리큘럼 인덱스

### Day 1 — 기초와 토큰 (3~4시간)

| # | 문서 | 내용 | 소요 |
|---|------|------|------|
| 01 | [디자이너를 위한 Copilot 개요](./day1/01-designer-copilot-overview.md) | Copilot이 디자이너 업무에서 돕는 12가지, Before/After | 40분 |
| 02 | [디자인 토큰 관리](./day1/02-design-tokens.md) | Color/Typography/Spacing JSON, 다크모드, W3C DTCG | 60분 |
| 03 | [디자이너를 위한 CSS](./day1/03-css-basics-for-designers.md) | Flexbox/Grid, CSS Variables, 카드 컴포넌트 실습 | 60분 |
| 04 | [Day 1 종합 실습](./day1/04-day1-lab.md) | 브랜드 리브랜딩: 팔레트 → 토큰 → CSS 3컴포넌트 | 60분 |

### Day 2 — 프로토타입과 문서화 (3~4시간)

| # | 문서 | 내용 | 소요 |
|---|------|------|------|
| 05 | [컴포넌트 스펙 문서화](./day2/05-component-spec.md) | Props/State/Variants/A11y 표, Storybook 스타일 | 50분 |
| 06 | [HTML 프로토타입](./day2/06-html-prototype.md) | Live Server, 반응형, 애니메이션, 랜딩 페이지 실습 | 70분 |
| 07 | [접근성과 품질 개선](./day2/07-accessibility-and-polish.md) | WCAG 2.1 AA, ARIA, 다크모드, 반응형 변환 | 50분 |
| 08 | [캡스톤 프로젝트](./day2/08-capstone.md) | SaaS 대시보드: 토큰 → 5컴포넌트 → HTML → 핸드오프 | 90분 |

---

## 부록

| 자료 | 설명 |
|------|------|
| [prompts.md](./prompts.md) | 디자이너용 프롬프트 치트시트 50개+ |
| [cheatsheet.md](./cheatsheet.md) | 1페이지 핵심 요약 (인쇄용) |
| [design-tokens-starter.json](./resources/templates/design-tokens-starter.json) | 시작 토큰 템플릿 (W3C DTCG 스타일) |
| [component-spec-template.md](./resources/templates/component-spec-template.md) | 컴포넌트 스펙 문서 템플릿 |
| [sample-landing-page.html](./resources/examples/sample-landing-page.html) | Copilot으로 만든 완성 랜딩 페이지 예시 |

---

## 학습 방법 권장

### 혼자 학습하는 경우

```
Day 1 오전: 01, 02 챕터 (이론 + 실습)
Day 1 오후: 03, 04 챕터 (실습 중심)
Day 2 오전: 05, 06 챕터
Day 2 오후: 07, 08 챕터 (캡스톤은 넉넉히 90분 잡기)
```

### 팀 워크숍으로 진행하는 경우

```
1일 집중 버전:
- 오전 (3h): 01 → 02 → 03 핵심만
- 오후 (3h): 05 → 06 → 08 캡스톤
- 02, 04, 07은 사전/사후 과제로
```

### 실습 파일 관리

각 실습은 `C:\Workspace\copilot-designer-lab\` 폴더를 만들어 거기서 작업하는 것을 권장합니다:

```
copilot-designer-lab/
├── tokens/           # 02 디자인 토큰 실습
├── components/       # 03 CSS 컴포넌트 실습
├── day1-lab/         # 04 Day 1 종합 실습
├── prototype/        # 06 HTML 프로토타입 실습
└── capstone/         # 08 캡스톤 프로젝트
```

---

## 이 과정에서 다루지 않는 것

| 주제 | 이유 |
|------|------|
| React / Vue / Svelte 컴포넌트 구현 | 프론트엔드 개발자 영역 |
| JavaScript 로직 심화 | 간단한 인터랙션만 다룸 |
| Figma 사용법 | 이미 알고 있다고 가정 |
| Photoshop / Illustrator | 별도 도구, 범위 외 |
| 디자인 원칙 이론 (게슈탈트 등) | 이미 알고 있다고 가정 |

---

**시작하기**: [Day 1 첫 번째 챕터 →](./day1/01-designer-copilot-overview.md)
