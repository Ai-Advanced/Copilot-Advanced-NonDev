# 07. 일반 오피스 워커를 위한 GitHub Copilot 2일 과정

> **대상**: 총무, 경영지원, 임원 비서, 사무 관리, 코디네이터, 부서 행정 담당 등  
> 특정 기술 직군이 아닌 **사무 운영 전반을 담당하는 모든 분**을 위한 과정입니다.

---

## 이 과정이 여러분에게 필요한 이유

하루 업무를 떠올려보세요. 이런 일들이 있지 않나요?

- 비슷한 이메일을 매일 조금씩 바꿔 쓴다
- 회의록을 받아서 요약하고 담당자별로 정리한다
- 엑셀에서 부서별 인원 수나 합계를 뽑는데 수식이 기억 안 난다
- PPT 초안을 만들어야 하는데 목차부터 막힌다
- 파일 이름을 날짜 순으로 바꾸는 작업을 수백 개씩 반복한다

이 중 **80%는 Copilot이 초안을 만들어줄 수 있습니다.** 여러분은 검토하고 다듬기만 하면 됩니다.

이 과정을 마치면 다음날 바로 업무에 씁니다. 코딩 지식은 전혀 필요 없습니다.

---

## 사전 준비

### 필수 설치 (과정 시작 전 완료)

| 항목 | 방법 |
|------|------|
| VS Code | [code.visualstudio.com](https://code.visualstudio.com/) 에서 무료 설치 |
| GitHub Copilot 확장 | VS Code > 확장(Extensions) > `GitHub Copilot` 검색 후 설치 |
| GitHub Copilot Chat 확장 | 같은 방법으로 `GitHub Copilot Chat` 추가 설치 |
| GitHub 계정 + 라이선스 | [github.com](https://github.com/) 가입 + Copilot 라이선스 활성화 |
| Korean Language Pack | VS Code > 확장 > `Korean Language Pack` (한국어 UI 원하는 분) |

### Windows 환경 확인

```
Win + X → "Windows PowerShell" 또는 "터미널" 열기
→ powershell 입력 후 Enter
→ 버전 확인: $PSVersionTable.PSVersion
→ 5.x 이상이면 OK (7.x 권장)
```

### macOS 환경 (참고)

이 과정은 Windows 우선으로 작성되었습니다. macOS 사용자는 PowerShell 예시에서 `zsh` 또는 `bash` 대안을 병기한 부분을 참고하세요.

### 공통 기초 선행 여부 확인

`00-basics/` 5개 문서를 먼저 완료했는지 확인하세요.

- [ ] `01-copilot-overview.md` 완료
- [ ] `02-installation.md` 완료
- [ ] `03-chat-vs-inline.md` 완료
- [ ] `04-prompt-basics.md` 완료
- [ ] `05-file-types-nondev.md` 완료

---

## 2일 커리큘럼 개요

### Day 1 — 기본기 + 이메일 + 엑셀 (약 3.5~4시간)

| 시간 | 챕터 | 내용 |
|------|------|------|
| 0:00~0:40 | `01-office-copilot-overview.md` | 오피스 업무 분석, Copilot 절감 포인트 15개 |
| 0:40~1:40 | `02-email-writing-mastery.md` | 이메일 완전 정복 (톤, 상황별, 한/영) |
| 1:40~2:00 | 휴식 | |
| 2:00~3:10 | `03-excel-formulas-basics.md` | 실무 엑셀 수식 + Copilot 프롬프팅 |
| 3:10~4:00 | `04-day1-lab.md` | Day 1 종합 실습: 주간 부서 보고 준비 |

### Day 2 — 회의록 + PPT + 파일 자동화 + 캡스톤 (약 4시간)

| 시간 | 챕터 | 내용 |
|------|------|------|
| 0:00~1:00 | `05-meeting-notes-summarization.md` | 회의록 자동 정리 + 액션아이템 추출 |
| 1:00~2:00 | `06-ppt-outline-and-drafts.md` | PPT 초안 자동화 (목차 → 슬라이드 초안) |
| 2:00~2:15 | 휴식 | |
| 2:15~3:15 | `07-file-and-folder-automation.md` | PowerShell 파일 자동화 스크립트 |
| 3:15~4:00 | `08-capstone.md` | 캡스톤: 월간 부서 운영 자동화 |

---

## 이 과정에서 만드는 결과물

2일이 끝나면 여러분 손에 남는 것들입니다.

### Day 1 결과물
- 톤별(정중/친근/단호) 이메일 템플릿 10종
- 근태 집계 엑셀 수식 세트
- 주간 부서 보고용 이메일 초안 3건 + 요약 시트

### Day 2 결과물
- 회의록 → 요약 + 액션 리스트 변환 워크플로우
- 20분 발표 PPT 목차 + 슬라이드별 초안
- 다운로드 폴더 자동 정리 PowerShell 스크립트
- 월간 부서 운영 자동화 패키지 (회의록 + 리포트 + 백업 + PPT)

---

## 학습 원칙

### 1. 눈이 아니라 손으로

모든 챕터에 실습이 있습니다. 반드시 직접 입력해보세요. 읽기만 해서는 이틀 후에 아무것도 남지 않습니다.

### 2. 내 업무 데이터로

예시 데이터 대신 실제 여러분의 업무 상황으로 바꿔서 해보면 습득 속도가 3배 빠릅니다.

### 3. 초안은 Copilot, 검증은 나

Copilot이 만든 이메일이나 수식은 반드시 한 번 검토 후 발송/사용합니다. AI는 틀릴 수 있습니다.

### 4. 50%만 써도 성공

모든 기능을 외울 필요 없습니다. "이런 게 가능하구나"를 알고, 필요할 때 이 자료를 다시 펼치면 됩니다.

---

## 폴더 구조

```
07-office-worker/
├── README.md                          ← 지금 이 파일
├── prompts.md                         ← 프롬프트 치트시트 50개+
├── cheatsheet.md                      ← 1페이지 핵심 요약
├── day1/
│   ├── 01-office-copilot-overview.md  ← 오피스 업무 분석
│   ├── 02-email-writing-mastery.md    ← 이메일 완전 정복
│   ← 03-excel-formulas-basics.md     ← 엑셀 수식 실무
│   └── 04-day1-lab.md                ← Day 1 종합 실습
├── day2/
│   ├── 05-meeting-notes-summarization.md  ← 회의록 자동화
│   ├── 06-ppt-outline-and-drafts.md       ← PPT 초안 자동화
│   ├── 07-file-and-folder-automation.md   ← 파일 자동화
│   └── 08-capstone.md                     ← 캡스톤 프로젝트
└── resources/
    ├── templates/
    │   ├── email-templates-korean.md      ← 이메일 템플릿 20종
    │   └── meeting-notes-template.md      ← 회의록 표준 템플릿
    └── examples/
        └── powershell-file-automation.ps1 ← PowerShell 예시 스크립트
```

---

## 자주 묻는 질문

**Q. 코딩을 전혀 몰라도 되나요?**  
네, 전혀 몰라도 됩니다. PowerShell 스크립트 챕터도 "이 스크립트를 이렇게 쓴다"는 수준으로 다룹니다. 스크립트를 처음부터 직접 짜는 게 아니라 Copilot이 만들어주면 실행만 합니다.

**Q. Mac 사용자인데 괜찮나요?**  
이 과정은 Windows 우선이지만, 이메일·회의록·PPT 챕터는 OS에 무관합니다. 파일 자동화 챕터에서 PowerShell 대신 `zsh` 명령어 대안을 병기해두었습니다.

**Q. 회사에서 GitHub Copilot을 쓸 수 있는지 모릅니다.**  
IT 팀 또는 관리자에게 "GitHub Copilot Business/Enterprise 라이선스가 있는지" 확인하세요. 없다면 개인 라이선스($10/월)로도 이 과정 전체 수행 가능합니다.

**Q. M365 Copilot(Word/Excel 안에 있는 Copilot)과 다른 건가요?**  
다른 제품입니다. 이 과정은 VS Code 안에서 동작하는 **GitHub Copilot** 기준입니다. M365 Copilot이 있으면 병행해서 쓸 수 있지만, 이 과정에서는 다루지 않습니다.

**Q. 실습 파일을 어디에 저장해야 하나요?**  
`C:\workspace\office-copilot\` 같은 전용 폴더를 하나 만들어두고 거기서 작업하면 편합니다. VS Code에서 해당 폴더를 열면 Copilot이 폴더 내 모든 파일의 맥락을 함께 참조합니다.

---

## 시작하기

준비가 되었다면 Day 1 첫 번째 챕터로 이동하세요.

→ **[day1/01-office-copilot-overview.md](./day1/01-office-copilot-overview.md)**
