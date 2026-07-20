# 기획 / PM — GitHub Copilot 2일 심화 과정

> **대상**: 프로덕트 매니저, 서비스 기획자, 프로덕트 오너, IT 기획팀
> **기간**: 2일 (각 3~4시간, 총 6~8시간)
> **선행 조건**: [00-basics/](../00-basics/) 5개 문서 완료

---

## 이 과정에서 무엇을 배우나

PRD 한 장 쓰는 데 반나절이 걸렸다면, Copilot 이후엔 1시간으로 줄어듭니다.
개발자 PR을 읽다가 포기했다면, Copilot에게 "이게 무슨 코드야?"라고 물어보면 됩니다.
회의록을 JIRA 티켓으로 옮기는 일이 귀찮았다면, Copilot이 초안 8개를 3분 안에 뽑아줍니다.

이 과정은 PM/기획자가 **실제로 시간을 잃는 업무들**에 Copilot을 직접 끼워 넣는 훈련입니다.

---

## 학습 목표

Day 1을 마치면:
- PRD / 기획서 초안을 Copilot으로 30분 안에 구조화할 수 있다
- 사용자 스토리 20개를 프롬프트 3번으로 뽑아낼 수 있다
- Copilot Instruction 파일로 사내 PRD 형식을 학습시킬 수 있다

Day 2를 마치면:
- 개발자의 PR / 코드를 Copilot 도움으로 읽고 맥락을 파악할 수 있다
- 회의록 하나를 JIRA 티켓 8개로 변환하는 프롬프트를 쓸 수 있다
- 개발자 없이 HTML 클릭 가능 프로토타입을 Copilot으로 만들 수 있다
- 신규 서비스 기획을 PRD부터 스프린트 티켓까지 end-to-end로 작성할 수 있다

---

## 대상자 정의

| 역할 | 이 과정이 맞는가 |
|------|----------------|
| 프로덕트 매니저 (PM) | ✅ 핵심 대상 |
| 서비스 기획자 | ✅ 핵심 대상 |
| 프로덕트 오너 (PO) | ✅ 핵심 대상 |
| IT 전략 기획팀 | ✅ 적합 |
| 스타트업 창업자 (기획 겸직) | ✅ 적합 |
| 마케터 (기획 업무 일부) | ⚠️ 일부 해당, 03-marketer 병행 권장 |
| UX 디자이너 | ⚠️ 일부 해당, 02-designer 병행 권장 |
| 개발자 | ❌ Copilot-Advanced-MSA-Java 과정 수강 권장 |

**이 과정이 다루지 않는 것**:
- Figma 플러그인 활용 (디자이너 과정에서 다룸)
- 광고 카피 / 마케팅 문구 (마케터 과정에서 다룸)
- 재무 모델링 / 엑셀 수식 (재무 과정에서 다룸)

---

## 커리큘럼 인덱스

### Day 1 — 문서 생산성 3배 높이기 (3~4시간)

| 순서 | 파일 | 주제 | 소요 시간 |
|------|------|------|-----------|
| 1 | [01-pm-copilot-overview.md](./day1/01-pm-copilot-overview.md) | PM 업무에서 Copilot이 바꾸는 것 | 40분 |
| 2 | [02-prd-writing.md](./day1/02-prd-writing.md) | PRD / 기획서 초안 작성 | 60분 |
| 3 | [03-user-stories-requirements.md](./day1/03-user-stories-requirements.md) | 사용자 스토리 & 요구사항 정의 | 50분 |
| 4 | [04-day1-lab.md](./day1/04-day1-lab.md) | Day 1 종합 실습 | 60분 |

### Day 2 — 협업 & 고급 활용 (3~4시간)

| 순서 | 파일 | 주제 | 소요 시간 |
|------|------|------|-----------|
| 5 | [05-code-reading-for-pm.md](./day2/05-code-reading-for-pm.md) | 개발자와 대화하기 위한 코드 읽기 | 50분 |
| 6 | [06-meeting-to-jira.md](./day2/06-meeting-to-jira.md) | 회의록 → JIRA/Notion 티켓 자동화 | 50분 |
| 7 | [07-prototype-with-html.md](./day2/07-prototype-with-html.md) | Copilot으로 인터랙티브 프로토타입 | 50분 |
| 8 | [08-capstone.md](./day2/08-capstone.md) | 캡스톤: 신규 서비스 기획 A~Z | 80분 |

---

## 소요 시간 상세표

```
Day 1  (총 ~3시간 30분)
├── 01-pm-copilot-overview    40분  (이론 15분 + 실습 25분)
├── 02-prd-writing            60분  (이론 20분 + 실습 40분)
├── 03-user-stories           50분  (이론 15분 + 실습 35분)
└── 04-day1-lab               60분  (실습 위주)
    소계: 3시간 30분

Day 2  (총 ~3시간 50분)
├── 05-code-reading           50분  (이론 20분 + 실습 30분)
├── 06-meeting-to-jira        50분  (이론 15분 + 실습 35분)
├── 07-prototype              50분  (이론 10분 + 실습 40분)
└── 08-capstone               80분  (실습 70분 + 리뷰 10분)
    소계: 3시간 50분

총합: 약 7시간 20분
```

---

## 이 직군 특화 Copilot 활용 시나리오 요약

아래 7가지가 이 과정에서 배우는 핵심 시나리오입니다.

### 1. PRD 초안 30분 완성

Copilot Instruction 파일에 사내 PRD 형식을 미리 정의해두면, 프롬프트 한 번으로 회사 형식에 맞는 초안이 나옵니다. 이후엔 내용만 채우면 됩니다.

### 2. 사용자 스토리 대량 생성

"회원가입 기능의 사용자 스토리 20개, INVEST 원칙에 따라" 같은 프롬프트 하나로, 엣지케이스까지 포함한 스토리를 뽑아낼 수 있습니다.

### 3. 개발자 PR 이해

개발자가 올린 Pull Request 코드를 복사해서 Copilot Chat에 붙이고 "PM 입장에서 이 변경이 어떤 기능에 영향을 주는지 설명해줘"라고 하면 됩니다.

### 4. API 명세 번역

Swagger / OpenAPI 문서를 Copilot에게 붙여넣고 "이 API가 하는 일을 비기술적 언어로 설명해줘"라고 하면 기획 문서에 바로 쓸 수 있는 설명이 나옵니다.

### 5. 회의록 → JIRA 티켓

30분 회의록 텍스트를 붙여넣고 "JIRA 티켓 초안으로 변환해줘, 담당자/우선순위/스토리 포인트 포함"으로 8개 티켓을 3분 안에 생성합니다.

### 6. 클릭 가능한 HTML 프로토타입

"로그인 → 대시보드 → 상세 페이지 3화면짜리 HTML 프로토타입"을 Copilot에게 요청하면, Figma 없이 개발자에게 보여줄 수 있는 목업이 나옵니다.

### 7. 이해관계자 커뮤니케이션 자동화

임원 보고용 1페이지 요약, 개발팀 전달용 기술 스펙, 디자인팀 전달용 UX 요구사항을 같은 PRD에서 각각 다른 톤으로 Copilot이 뽑아줍니다.

---

## 사전 준비 체크리스트

**필수 (공통)**
- [ ] VS Code 최신 버전 설치
- [ ] GitHub Copilot 라이선스 활성화
- [ ] VS Code 확장: `GitHub Copilot` + `GitHub Copilot Chat` 설치 및 로그인
- [ ] 00-basics/ 5개 문서 완료

**PM/기획자 추가 준비물**
- [ ] 현재 진행 중인 프로젝트의 기획서 1개 (실습 소재로 활용)
- [ ] 최근 회의록 1개 (Day 2 실습용)
- [ ] 사내 PRD/기획서 템플릿 (있다면 — Copilot에 학습시키는 실습에 사용)

**권장 VS Code 확장**
- [ ] `Markdown Preview Enhanced` — 더 나은 Markdown 미리보기
- [ ] `YAML` (Red Hat) — API 명세 파일 지원

---

## 학습 방법 권장

**혼자 학습**: Day 1 → Day 2 순서를 하루씩 나눠서 진행합니다. 각 실습은 반드시 손으로 해보세요.

**팀 워크숍**: 강사가 각 챕터 이론 부분을 15~20분 설명하고, 이후 참가자가 실습합니다. Day 1 오전 / Day 2 오후 형식으로 하루에 몰아서 진행도 가능합니다.

**팀 스터디**: 매주 2챕터씩 4주에 걸쳐 완주합니다.

---

## 리소스 파일

| 파일 | 설명 | 활용 시점 |
|------|------|-----------|
| [prompts.md](./prompts.md) | PM용 프롬프트 치트시트 50개 | 과정 중 언제든 |
| [cheatsheet.md](./cheatsheet.md) | 1페이지 핵심 요약 | 실무 복귀 후 참고 |
| [resources/templates/prd-template.md](./resources/templates/prd-template.md) | 붙여넣기 바로 사용 PRD 템플릿 | Day 1 실습 |
| [resources/templates/user-story-template.md](./resources/templates/user-story-template.md) | 사용자 스토리 + 인수 조건 템플릿 | Day 1 실습 |
| [resources/examples/sample-prd-completed.md](./resources/examples/sample-prd-completed.md) | 완성된 PRD 예시 (주석 포함) | Day 1 참고 |

---

**시작**: [Day 1 첫 번째 문서 →](./day1/01-pm-copilot-overview.md)
