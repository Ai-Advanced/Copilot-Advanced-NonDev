# PM / 기획자 Copilot 치트시트

> 1페이지 요약 — 실무 복귀 후 빠른 참고용

---

## 핵심 단축키

| 동작 | Windows | Mac |
|------|---------|-----|
| Tab 자동완성 수락 | `Tab` | `Tab` |
| 자동완성 무시 | `Esc` | `Esc` |
| 다른 제안 보기 | `Alt + ]` / `Alt + [` | `Option + ]` / `Option + [` |
| Inline Chat 열기 | `Ctrl + I` | `Cmd + I` |
| Chat 사이드바 열기 | `Ctrl + Alt + I` | `Cmd + Option + I` |
| Markdown 미리보기 | `Ctrl + K V` | `Cmd + K V` |
| 파일 저장 | `Ctrl + S` | `Cmd + S` |
| 파일 내 검색 | `Ctrl + F` | `Cmd + F` |

---

## 3가지 상호작용 방식 선택 기준

```
타이핑 중 다음 내용 자동 완성     →  Tab 자동완성 (그냥 계속 쓰면 됨)
커서 위치에 뭔가 삽입/수정        →  Ctrl+I (Inline Chat)
질문하거나 긴 대화가 필요         →  Ctrl+Alt+I (Chat 사이드바)
```

---

## PM 핵심 워크플로우

### PRD 작성 플로우
```
1. prd-draft.md 파일 생성
2. 파일 상단에 제품/기능 컨텍스트 주석 작성
3. Chat: "PRD 초안 골격 생성" 프롬프트 (prompts.md 1-1)
4. Tab 자동완성으로 섹션별 내용 채우기
5. Chat: "PRD 검토 요청" 프롬프트 (prompts.md 1-6)
6. 수정 → 저장
```

### 회의록 → 티켓 플로우
```
1. meeting-notes.md에 회의 메모 작성
2. 전체 선택 (Ctrl+A) → Chat 창에 붙여넣기
3. "회의록 → JIRA 티켓 변환" 프롬프트 (prompts.md 3-2)
4. 결과를 tickets.md에 저장
5. 각 티켓 내용 검토 후 JIRA에 수동 입력
```

### HTML 프로토타입 플로우
```
1. prototype.html 파일 생성
2. Chat: "HTML 프로토타입 페이지 생성" 프롬프트 (prompts.md 5-1)
3. 결과 코드를 파일에 붙여넣기
4. 브라우저로 열기 (파일 탐색기에서 더블클릭)
5. 이해관계자에게 파일 공유
```

---

## 자주 쓰는 프롬프트 TOP 10

| # | 상황 | 핵심 프롬프트 키워드 |
|---|------|---------------------|
| 1 | PRD 초안 | `PRD 초안 Markdown으로, 섹션: 배경/목표/스토리/명세/스코프/리스크/일정` |
| 2 | 사용자 스토리 생성 | `As a..., I want..., so that... 형식으로 15개, 엣지케이스 포함` |
| 3 | 회의록 구조화 | `회의록 Markdown으로: 목적/논의/결정/액션아이템/다음안건` |
| 4 | JIRA 티켓 변환 | `타입/우선순위/담당자/스토리포인트/설명/인수조건 형식으로 티켓 추출` |
| 5 | 코드 설명 요청 | `PM 관점에서, 기술 용어 없이, 사용자 영향 중심으로 설명` |
| 6 | 임원 요약 | `1페이지, 숫자 중심, 문제→해결→효과→요청사항` |
| 7 | 엣지케이스 발굴 | `입력/권한/동시성/네트워크/비즈니스규칙 관점에서 각 3개` |
| 8 | HTML 목업 | `HTML+CSS, 클릭 가능, 모바일(390px), 플레이스홀더 텍스트` |
| 9 | MoSCoW 분류 | `Must/Should/Could/Won't Have, 각 이유 한 줄` |
| 10 | API 명세 이해 | `비기술자용, 기능/입력/응답/에러/제약 설명` |

---

## 좋은 프롬프트 체크리스트

```
□ 목적이 명확한가? (무엇을 만들어야 하는가)
□ 독자/대상이 명시되었는가?
□ 형식이 지정되었는가? (Markdown / 표 / JSON / HTML)
□ 길이/개수가 지정되었는가?
□ 포함해야 할 항목이 나열되었는가?
□ 제외할 것도 명시했는가?
□ 변수명/파일명은 영어로 명시했는가?
```

---

## AI가 자주 실수하는 것 (PM 관점)

| 실수 유형 | 증상 | 대처 |
|----------|------|------|
| 수치 환각 | 없는 통계·URL을 생성 | 수치는 직접 채워 넣기 |
| 모호한 인수 조건 | "적절히", "빠르게" 같은 표현 | "3초 이내", "100자 이내"로 교체 |
| 스코프 팽창 | 요청하지 않은 기능 추가 | "이번 버전 스코프 외" 명시 |
| 기술 편향 | 개발 관점으로만 설명 | "사용자 관점으로" 재요청 |
| 일반론 나열 | 구체성 없는 뻔한 내용 | 실제 데이터/맥락 추가 후 재요청 |

---

## Copilot Instruction 파일 활용

회사 PRD 형식을 Copilot에 학습시키는 방법:

```
1. .github/copilot-instructions.md 파일 생성
2. 다음 내용 작성:
   ---
   이 프로젝트는 PM 기획 문서 작업 공간입니다.
   PRD 작성 시 다음 형식을 따릅니다: [회사 형식 설명]
   사용자 스토리는 한국어로, 기술 용어는 영어로 작성합니다.
   우선순위는 MoSCoW 방식을 사용합니다.
   ---
3. 이후 PRD 작업 시 자동으로 회사 형식 반영
```

---

## 참고 파일 경로

- 프롬프트 전체 목록: [prompts.md](./prompts.md)
- PRD 템플릿: [resources/templates/prd-template.md](./resources/templates/prd-template.md)
- 사용자 스토리 템플릿: [resources/templates/user-story-template.md](./resources/templates/user-story-template.md)
- 완성 PRD 예시: [resources/examples/sample-prd-completed.md](./resources/examples/sample-prd-completed.md)
