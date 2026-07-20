# 05. 컴포넌트 스펙 문서화

## 학습 목표

- Storybook 스타일의 컴포넌트 스펙 문서 구조 이해
- Props / State / Variants / Accessibility 표를 Copilot으로 빠르게 작성
- 개발자가 실제로 쓸 수 있는 handoff 수준의 스펙 완성
- 실습: Button 컴포넌트 완전 스펙 문서 작성

**예상 소요**: 50분

---

## 5.1 왜 컴포넌트 스펙이 필요한가

Figma 파일만 넘기면 끝일까요? 실무에서는 그렇지 않습니다.

| 스펙 없이 | 스펙 있을 때 |
|-----------|-------------|
| 개발자가 Figma 보며 "이게 hover인가요?" 질문 | hover, active, focus 상태 모두 표 정의 |
| "disabled일 때 이렇게 해야 하나요?" 슬랙 DM | disabled 시각/동작 명시 |
| 개발자가 Props 이름을 임의로 결정 | 설계된 Props 인터페이스로 일관성 유지 |
| 모바일에서 깨졌을 때 "디자인에 없었어요" | 반응형 동작 명시 |
| 접근성 오류 나중에 발견 | 처음부터 ARIA 요건 포함 |

**결론**: 스펙 문서 1개가 슬랙 메시지 20개를 없앱니다.

---

## 5.2 스펙 문서 구조

아래가 이 챕터에서 다루는 표준 구조입니다.

```
ComponentName.md
├── 1. 개요
│   ├── 한 줄 설명
│   ├── 언제 사용하는가
│   └── Figma 링크
├── 2. Props
│   └── 표: 이름 | 타입 | 기본값 | 필수 | 설명
├── 3. Variants
│   └── 표: variant | 시각적 설명 | 사용 사례
├── 4. States
│   └── 표: 상태 | 트리거 | 시각적 변화
├── 5. 반응형 동작
├── 6. 접근성
│   ├── ARIA 속성
│   ├── 키보드 동작
│   └── 스크린 리더 발화
├── 7. DO / DON'T
└── 8. 변경 이력
```

---

## 5.3 Props 테이블

Props는 컴포넌트의 외부 인터페이스입니다. 어떤 값을 넣으면 어떻게 동작하는지를 정의합니다.

### 타입 표기 규칙

| 타입 | 표기법 | 예시 |
|------|--------|------|
| 문자열 | `string` | label, href |
| 숫자 | `number` | size, count |
| 불리언 | `boolean` | disabled, loading |
| 열거형 | `'값1' \| '값2'` | `'primary' \| 'secondary'` |
| 함수 | `() => void` | onClick |
| React 노드 | `ReactNode` | children, icon |
| HTML 속성 | `HTMLAttributes<...>` | 나머지 HTML 속성 전파 |

### Button Props 예시

Copilot에게 이렇게 요청합니다:

```
Button 컴포넌트의 Props 테이블을 Markdown으로 만들어줘.

Props 목록:
- variant: 버튼 스타일 종류
- size: 버튼 크기
- disabled: 비활성화
- loading: 로딩 중 (스피너 표시 + 클릭 방지)
- leftIcon: 버튼 텍스트 왼쪽 아이콘
- rightIcon: 버튼 텍스트 오른쪽 아이콘
- fullWidth: 부모 너비 100% 차지
- onClick: 클릭 이벤트
- type: HTML button type (submit, button, reset)
- children: 버튼 레이블 (ReactNode)

표 열: 이름 | 타입 | 기본값 | 필수 | 설명
variant 타입: 'primary' | 'secondary' | 'ghost' | 'danger' | 'link'
size 타입: 'sm' | 'md' | 'lg'
```

결과:

| 이름 | 타입 | 기본값 | 필수 | 설명 |
|------|------|--------|:----:|------|
| `variant` | `'primary' \| 'secondary' \| 'ghost' \| 'danger' \| 'link'` | `'primary'` | | 버튼의 시각적 스타일 |
| `size` | `'sm' \| 'md' \| 'lg'` | `'md'` | | 버튼 크기 |
| `disabled` | `boolean` | `false` | | 비활성화 상태. 클릭 이벤트 차단 |
| `loading` | `boolean` | `false` | | 로딩 중 상태. 스피너 표시, 클릭 방지 |
| `leftIcon` | `ReactNode` | `undefined` | | 레이블 왼쪽 아이콘 |
| `rightIcon` | `ReactNode` | `undefined` | | 레이블 오른쪽 아이콘 |
| `fullWidth` | `boolean` | `false` | | `true`일 때 부모 너비 100% |
| `onClick` | `(e: MouseEvent) => void` | `undefined` | | 클릭 이벤트 핸들러 |
| `type` | `'button' \| 'submit' \| 'reset'` | `'button'` | | HTML button type |
| `children` | `ReactNode` | | ✅ | 버튼 레이블 콘텐츠 |

---

## 5.4 Variants 테이블

Variants는 같은 컴포넌트의 시각적 변형입니다.

```
Button Variants 표를 Markdown으로 작성해줘.

Variants:
1. primary: 채워진 브랜드 컬러 버튼 (가장 강조)
2. secondary: 연한 배경 + 어두운 텍스트 (보조 액션)
3. ghost: 투명 배경 + 테두리 (3순위 액션)
4. danger: 빨간 배경 (파괴적 액션: 삭제, 취소)
5. link: 밑줄 텍스트 버튼 (인라인 액션)

표 열: variant | 배경 | 텍스트 | 테두리 | 사용 사례 | 예시
```

결과:

| variant | 배경 | 텍스트 | 테두리 | 사용 사례 | 예시 |
|---------|------|--------|--------|-----------|------|
| `primary` | 브랜드 컬러 | 흰색 | 없음 | 페이지 주 CTA, 폼 제출 | "저장", "시작하기" |
| `secondary` | 연한 회색 | 다크 그레이 | 없음 | 보조 액션, 취소 | "뒤로", "닫기" |
| `ghost` | 투명 | 브랜드 컬러 | 브랜드 컬러 1px | 3순위 액션, 필터 버튼 | "더보기", "필터" |
| `danger` | 빨간색 | 흰색 | 없음 | 삭제, 영구 취소 | "삭제", "탈퇴" |
| `link` | 투명 | 브랜드 컬러 | 없음 (밑줄) | 인라인 텍스트 링크 | "자세히 보기" |

---

## 5.5 States 테이블

States는 사용자 상호작용에 따른 시각적 변화입니다.

```
Button States 표를 Markdown으로 작성해줘.

States: default / hover / active / focus-visible / disabled / loading

표 열: 상태 | 트리거 | 시각적 변화 | 지속 조건
primary variant 기준.
```

결과:

| 상태 | 트리거 | 시각적 변화 | 지속 조건 |
|------|--------|-------------|-----------|
| `default` | 기본 | 기준 스타일 | 다른 상태가 아닐 때 |
| `hover` | 마우스 오버 | 배경색 10% 어둡게, cursor pointer | 마우스가 위에 있는 동안 |
| `active` | 마우스 클릭 중 | scale(0.97), 배경 20% 어둡게 | 클릭 누르고 있는 동안 |
| `focus-visible` | 키보드 Tab | 외곽에 3px 링 (브랜드 컬러 40% 투명) | 키보드 포커스 중 |
| `disabled` | `disabled={true}` | opacity 0.5, cursor not-allowed | `disabled` prop이 true인 동안 |
| `loading` | `loading={true}` | 레이블 숨김, 스피너 표시, cursor wait | `loading` prop이 true인 동안 |

---

## 5.6 접근성 스펙

접근성은 스펙 문서의 필수 섹션입니다. 나중에 추가하면 구현이 두 배로 복잡해집니다.

```
Button 컴포넌트 접근성 스펙을 작성해줘.

포함할 것:
1. ARIA 속성 표 (속성 | 값 | 설명)
2. 키보드 동작 표 (키 | 동작)
3. 스크린 리더 발화 예시
4. 주의사항 (디자이너가 놓치기 쉬운 것)
```

결과 예시:

**ARIA 속성**

| 속성 | 값 | 설명 |
|------|----|------|
| `role` | `"button"` (기본) | `<button>` 태그면 자동. `<div>` 사용 시 명시 필요 |
| `aria-disabled` | `true / false` | `disabled` prop 상태 반영 |
| `aria-busy` | `true / false` | `loading` 상태 반영 |
| `aria-label` | 문자열 | 아이콘만 있는 버튼에 필수. 예: `aria-label="삭제"` |
| `aria-pressed` | `true / false` | 토글 버튼의 경우 |

**키보드 동작**

| 키 | 동작 |
|----|------|
| `Tab` | 포커스 이동 (다음 인터랙티브 요소로) |
| `Shift+Tab` | 포커스 역방향 이동 |
| `Enter` | 버튼 실행 |
| `Space` | 버튼 실행 (`<button>` 태그 기본 동작) |

**스크린 리더 발화**

```
기본: "저장, 버튼"
disabled: "저장, 버튼, 비활성화됨"
loading: "저장, 버튼, 바쁨"
아이콘만: aria-label 없으면 → 아무것도 읽지 않음 (❌)
아이콘만: aria-label="삭제" → "삭제, 버튼" (✅)
```

---

## 5.7 DO / DON'T 가이드

사용 가이드는 새로운 팀원이나 외부 기여자가 컴포넌트를 잘못 쓰는 것을 방지합니다.

```
Button 컴포넌트 DO/DON'T 가이드를 작성해줘.

각 5가지씩, 표 형식:
| ✅ DO | ❌ DON'T | 이유 |

실수하기 쉬운 패턴:
- 버튼 중첩 사용
- 아이콘만 있는 버튼에 aria-label 누락
- 레이블 없이 variant만으로 의미 전달
- 하나의 화면에 primary 버튼 여러 개
- danger를 오용
```

결과:

| ✅ DO | ❌ DON'T | 이유 |
|-------|---------|------|
| 아이콘만 있는 버튼에 `aria-label` 추가 | 아이콘만 있는 버튼을 레이블 없이 사용 | 스크린 리더 사용자가 기능을 알 수 없음 |
| 한 화면에 primary 버튼 1개 | 같은 화면에 primary 버튼 3개 | 시각적 계층이 무너져 사용자가 혼란 |
| 파괴적 액션에만 `danger` 사용 | 경고 메시지나 알림에 `danger` 버튼 | danger는 삭제/취소 등 되돌릴 수 없는 액션 전용 |
| `loading` prop으로 로딩 표현 | 버튼 레이블을 "로딩 중..."으로 직접 변경 | prop 기반이 일관성 있고 접근성도 자동 처리 |
| `type="submit"`은 폼 제출에만 | 모든 버튼에 `type="submit"` | 폼 내부에서 예기치 않게 폼 제출 트리거 가능 |

---

## 실습

### 실습: Button 컴포넌트 완전 스펙 문서

`button-spec.md` 파일을 새로 만들고 아래 단계로 완성합니다.

**단계 1. 기본 구조 생성**

Chat 사이드바에서:

```
Button 컴포넌트 스펙 문서 전체를 Markdown으로 작성해줘.

컴포넌트 정보:
- 이름: Button
- 버전: v1.0
- 디자인 시스템: Lumio (Day 1 실습 기준)
- Figma 링크: [추가 예정]

섹션 구성:
1. 개요 (한 줄 설명, 사용 시점, 사용하지 말아야 할 시점)
2. Props 표 (variant/size/disabled/loading/leftIcon/rightIcon/fullWidth/onClick/type/children)
3. Variants 표 (primary/secondary/ghost/danger/link)
4. States 표 (default/hover/active/focus-visible/disabled/loading)
5. 반응형 동작 (모바일 터치 타겟 44px 이상)
6. 접근성 (ARIA 속성 표, 키보드 동작 표, 스크린 리더 발화)
7. DO/DON'T (각 5가지)
8. 코드 사용 예시 (HTML 기준 3가지 예시)
9. 관련 컴포넌트 (IconButton, ButtonGroup 언급)
10. 변경 이력 (첫 줄: 2026-07-20 | v1.0 | 초기 생성)

전체 문서, Markdown 형식.
```

**단계 2. 실제 Lumio 브랜드 값으로 업데이트**

Day 1에서 만든 `tokens.css`를 참고해서 색상 값들을 실제 Lumio 값으로 교체합니다.

```
위 스펙 문서에서 색상 값을 Lumio 브랜드로 업데이트해줘.

Lumio 브랜드 값:
- brand.default: #F97316 (오렌지)
- primary hover: #EA580C
- secondary.50: #F0F9FF (블루 연한 배경)
- error.500: #EF4444

States 표와 Variants 표에서 hex 값 실제로 명시.
```

**단계 3. 코드 예시 추가**

```
button-spec.md의 코드 예시 섹션에 HTML 스니펫 5개를 추가해줘.

1. 기본 primary 버튼
2. 아이콘 + 텍스트 버튼
3. loading 상태 버튼
4. 아이콘만 있는 버튼 (aria-label 포함)
5. fullWidth 버튼 (폼 내부)

CSS 클래스 기준, Lumio 클래스명 사용 (.btn .btn-primary 등).
```

**완성 체크**

- [ ] Props 10개 모두 타입과 기본값 포함
- [ ] Variants 5가지 표 완성
- [ ] States 6가지 표 완성
- [ ] 접근성 3가지 섹션 완성
- [ ] DO/DON'T 각 5개
- [ ] 변경 이력 첫 줄 포함

---

## 핵심 포인트

1. **4대 테이블**: Props + Variants + States + Accessibility = 개발자가 필요한 것 90%
2. **타입 명시**: `string`이 아닌 `'primary' | 'secondary' | 'ghost'` 처럼 구체적으로
3. **상태 트리거**: "hover"가 아니라 "마우스 오버 시" — 트리거 조건까지 기술
4. **접근성 먼저**: 나중에 추가하면 구현 비용 2배, 처음부터 스펙에 포함
5. **DO/DON'T**: 이 섹션 하나가 슬랙 질문 10개를 예방

---

**다음 문서**: [06-html-prototype.md](./06-html-prototype.md) — HTML/CSS 클릭 가능 프로토타입 만들기
