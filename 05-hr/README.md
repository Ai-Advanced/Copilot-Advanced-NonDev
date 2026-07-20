# HR / 인사 — GitHub Copilot 2일 심화 과정

> **대상**: HRBP, 리크루터, 피플옵스, 조직문화 담당자
> **수준**: 00-basics/ 완료 후 진행
> **총 소요**: 6~8시간 (Day 1: 3~4시간 · Day 2: 3~4시간)

---

## 이 과정에서 만들 것들

2일이 끝나면 여러분의 손에는 실제로 쓸 수 있는 것들이 남습니다.

| 결과물 | 챕터 |
|--------|------|
| 편향(bias) 검토 완료된 JD 초안 | Day 1 - 02 |
| 시니어 PM 인터뷰 질문 세트 + 평가 루브릭 | Day 1 - 03 |
| 신규 마케터 90일 온보딩 플랜 | Day 2 - 05 |
| 인사 대시보드용 엑셀 수식 모음 | Day 2 - 06 |
| 분기 펄스 서베이 자동화 스크립트 | Day 2 - 07 |
| 시니어 개발자 채용 A~Z 캡스톤 패키지 | Day 2 - 08 |

---

## 왜 HR 담당자에게 Copilot이 필요한가

HR 업무는 **문서 집약적**입니다. JD 한 건을 제대로 쓰는 데 1~2시간, 인터뷰 질문 세트 구성에 30분, 온보딩 문서 정비에 반나절. 이 시간들을 Copilot으로 절반 이하로 줄이면, 남은 시간을 **사람을 만나는 일**에 쓸 수 있습니다.

HR 담당자가 Copilot으로 절약하는 대표 업무:

- **JD 작성**: 역할별 초안 5분 → 편향 검토 → 최종본 (기존 1~2시간 → 30분)
- **인터뷰 질문 설계**: BEI 기반 질문 세트 + 루브릭 (기존 1시간 → 15분)
- **온보딩 문서**: 역할별 90일 플랜, 웰컴 이메일, FAQ (기존 반나절 → 1시간)
- **HR 데이터 정리**: 급여밴드 계산, 근속 집계, 조직도 표 (기존 2시간 → 30분)
- **서베이 설계 및 집계**: 펄스 서베이 문항 + Apps Script 자동화

---

## 중요: HR에서 AI를 쓸 때 반드시 지켜야 할 원칙

이 과정 전반에 걸쳐 반복하는 내용이지만, 시작 전에 한 번 짚고 갑니다.

### 1. AI는 최종 채용 결정을 내리지 않습니다

Copilot(또는 어떤 AI 도구도) 이력서 스크리닝 결과를 그대로 채용/탈락 결정에 쓰면 안 됩니다. AI는 **초안과 보조 수단**이며, 최종 판단은 사람이 합니다.

> 법적 근거: 미국 EEOC, EU AI Act, 그리고 한국 근로기준법·채용절차법 모두 자동화된 채용 결정에 대해 규제를 강화하는 방향으로 움직이고 있습니다.

### 2. 개인정보는 Copilot에 입력하지 않습니다

실제 직원/지원자의 이름, 연락처, 주민등록번호, 급여 정보를 프롬프트에 넣지 마세요. 이 과정의 모든 예시는 **가상 인물·익명 데이터**를 씁니다.

> 법적 근거: 개인정보보호법 제17조 (제3자 제공 제한), 제18조 (목적 외 이용 금지).

### 3. 편향(bias) 제거는 Copilot이 만든 초안도 예외가 아닙니다

Copilot이 생성한 JD·인터뷰 질문에도 학력·성별·연령·외모 관련 편향 표현이 들어갈 수 있습니다. 이 과정에서 편향 검토 프롬프트를 반드시 사용하는 습관을 기르세요.

---

## 커리큘럼 지도

### Day 1 — 채용 핵심 서류 완성

| 챕터 | 주제 | 소요 |
|------|------|------|
| [01. HR의 하루와 Copilot](./day1/01-hr-copilot-overview.md) | Copilot 15가지 HR 활용, Before/After, 개인정보 주의사항 | 40분 |
| [02. JD 작성](./day1/02-jd-writing.md) | 좋은 JD 구조, 편향 언어 제거, 산업별 차이, 실습 | 60분 |
| [03. 인터뷰 질문 설계](./day1/03-interview-questions.md) | BEI·STAR, 컬처애드, 역할별 질문 세트, 평가 루브릭 | 60분 |
| [04. Day 1 종합 실습](./day1/04-day1-lab.md) | 채용 킥오프 패키지 (JD→편향검토→인터뷰→루브릭) | 50분 |

### Day 2 — 온보딩·데이터·자동화

| 챕터 | 주제 | 소요 |
|------|------|------|
| [05. 온보딩 문서화](./day2/05-onboarding-docs.md) | 90일 플랜, 웰컴 이메일, 역할별 체크리스트 | 60분 |
| [06. HR 엑셀과 데이터](./day2/06-hr-excel-and-data.md) | 급여밴드, 근속·휴가, PIVOT, 개인정보 마스킹 | 60분 |
| [07. 서베이 자동화](./day2/07-forms-and-surveys.md) | Google Forms + Apps Script, ENPS, 익명성 보장 | 50분 |
| [08. 캡스톤](./day2/08-capstone.md) | 시니어 개발자 채용 A~Z end-to-end | 60분 |

---

## 폴더 구조

```
05-hr/
├── README.md                          ← 지금 여기
├── prompts.md                         ← HR 프롬프트 치트시트 50개+
├── cheatsheet.md                      ← 1페이지 핵심 요약
├── day1/
│   ├── 01-hr-copilot-overview.md
│   ├── 02-jd-writing.md
│   ├── 03-interview-questions.md
│   └── 04-day1-lab.md
├── day2/
│   ├── 05-onboarding-docs.md
│   ├── 06-hr-excel-and-data.md
│   ├── 07-forms-and-surveys.md
│   └── 08-capstone.md
└── resources/
    ├── templates/
    │   ├── jd-template.md             ← 편향-프리 JD 템플릿
    │   └── onboarding-90days.md       ← 90일 온보딩 플랜 템플릿
    └── examples/
        └── interview-question-bank.md ← 역할별 질문 뱅크
```

---

## 사전 준비

**공통 (00-basics/ 완료 필수)**
- [ ] VS Code + GitHub Copilot 설치 완료
- [ ] Copilot Chat 사이드바 열기 확인

**HR 과정 추가 준비**
- [ ] Google 계정 (Apps Script 실습용)
- [ ] Microsoft Excel 또는 Google Sheets 접근 가능
- [ ] 연습용 익명 직원 데이터 준비 (이 과정의 `resources/` 템플릿 사용 가능)

**권장 VS Code 확장**
- `Excel Viewer` — CSV 파일을 표로 보기
- `Markdown Preview Enhanced` — 문서 미리보기

---

## 학습 방법 권장

이 과정은 **"읽기"가 아니라 "하기"** 중심입니다.

1. 각 챕터의 이론 섹션을 읽으며 개념 이해 (20%)
2. 프롬프트 예시를 **그대로 Copilot Chat에 입력** (40%)
3. 결과를 수정하며 자기 업무에 맞게 개선 (40%)

> **팁**: `prompts.md`를 VS Code에서 항상 열어두고, 실습 중 복사-붙여넣기 하세요.

---

## 이 과정에서 다루지 않는 것

- 일반 이메일·문서 작성 → [07-office-worker/](../07-office-worker/) 참고
- 재무/급여 시스템 연동 → [06-finance/](../06-finance/) 참고
- Python 프로그래밍 심화 → [08-data-analyst/](../08-data-analyst/) 참고
- ChatGPT, M365 Copilot (이 과정은 **GitHub Copilot** 전용)

---

**시작**: [Day 1 - 01. HR의 하루와 Copilot →](./day1/01-hr-copilot-overview.md)
