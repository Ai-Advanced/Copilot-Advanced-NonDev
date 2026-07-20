# 02. 설치와 설정 — VS Code + GitHub Copilot

## 학습 목표

- Windows / macOS에서 VS Code + Copilot을 처음부터 설치
- Copilot 라이선스 확인 및 로그인
- 첫 자동완성이 뜨는지 눈으로 확인 (Hello Copilot 테스트)

**예상 소요**: 15분 (인터넷 상태에 따라 ±5분)

---

## 2.1 사전 확인 사항

### GitHub Copilot 라이선스 확인

- **회사에서 라이선스를 받은 경우**: 회사 이메일로 초대장이 왔을 가능성이 큽니다. GitHub 계정 로그인 → 우측 상단 프로필 → **Settings** → 좌측 **Copilot** 메뉴에서 "Active" 확인
- **개인 구독**: [github.com/features/copilot](https://github.com/features/copilot) → "Get GitHub Copilot" → Individual $10/월 (첫 30일 무료 체험)

> **주의**: Copilot 라이선스가 없으면 확장 설치는 되지만 자동완성이 안 뜹니다.

---

## 2.2 VS Code 설치

### Windows

1. [code.visualstudio.com](https://code.visualstudio.com/) → **Download for Windows**
2. `VSCodeUserSetup-x64-*.exe` 실행
3. 설치 옵션에서 **"Add to PATH"** 반드시 체크 (터미널 사용 시 편함)
4. 완료 후 실행

### macOS

1. [code.visualstudio.com](https://code.visualstudio.com/) → **Download Mac Universal**
2. 다운로드한 `.zip` 압축 해제 → `Visual Studio Code.app`을 **Applications** 폴더로 드래그
3. Launchpad에서 실행

### 한글 UI로 바꾸기 (선택)

1. VS Code 실행 → `Ctrl+Shift+X` (Mac: `Cmd+Shift+X`) → Extensions 사이드바
2. 검색창에 `Korean Language Pack` → Microsoft 제공 확장 설치
3. 우측 하단 알림에서 **"Change Language and Restart"** 클릭

---

## 2.3 Copilot 확장 설치 (2개)

Extensions 사이드바에서 다음 **2개**를 순서대로 설치합니다.

### 1) GitHub Copilot

- 검색: `GitHub Copilot`
- 게시자가 **GitHub** 인지 확인 (유사한 이름의 다른 확장 있음)
- **Install** 클릭

### 2) GitHub Copilot Chat

- 검색: `GitHub Copilot Chat`
- 게시자 **GitHub** 확인
- **Install** 클릭

**두 개를 다 설치해야** 자동완성(1번) + 대화(2번)를 모두 쓸 수 있습니다.

---

## 2.4 로그인

### 자동 로그인 (권장)

1. 확장 설치가 끝나면 VS Code 우측 하단에 **"Sign in to GitHub"** 알림이 뜹니다
2. 클릭 → 브라우저가 열리며 GitHub 로그인 페이지로 이동
3. GitHub 계정 로그인 → **"Authorize Visual Studio Code"** 클릭
4. 브라우저에 "You're all set" 화면이 뜨면 성공. VS Code로 돌아옴

### 수동 로그인 (알림을 놓친 경우)

1. VS Code 좌측 하단 사람 모양 아이콘 → **Accounts** → **Sign in with GitHub to use GitHub Copilot**
2. 위와 동일한 브라우저 흐름 진행

### 로그인 성공 확인

- VS Code 우측 하단 상태 바에 **Copilot 아이콘**이 표시됨 (☑ 체크 표시)
- 아이콘 클릭 → 팝업에 **"Copilot is active"** 문구 확인

---

## 2.5 Hello Copilot 테스트 (3분)

### Step 1. 테스트 폴더 만들기

바탕화면에 `copilot-test`라는 폴더를 만들고, VS Code에서:
- **File → Open Folder** → 방금 만든 폴더 선택

### Step 2. 자동완성 확인 (.md 파일로)

1. VS Code에서 새 파일: `Ctrl+N` (Mac: `Cmd+N`)
2. 저장: `Ctrl+S` → 이름을 `hello.md`로 저장
3. 다음 문장을 그대로 타이핑:

```markdown
# 오늘의 할 일

1. 팀 스탠드업 미팅
2.
```

4. `2. ` 뒤에서 **1~2초 기다리면** 회색 글씨로 다음 항목 제안이 뜹니다
5. `Tab` 키를 눌러 수락하거나, `Esc`로 무시

**뜨지 않는다면**: 우측 하단 Copilot 아이콘 클릭 → 상태 확인. `Ctrl+Shift+P` → "Copilot: Enable Completions" 실행.

### Step 3. Chat 확인

1. `Ctrl+Alt+I` (Mac: `Cmd+Alt+I`) → 우측에 **Chat 사이드바**가 열림
2. 아무 질문이나 입력:
   ```
   Markdown에서 표를 만드는 문법 알려줘
   ```
3. AI가 답변 + 예시를 보여주면 성공

### Step 4. Inline Chat 확인

1. `hello.md` 파일 아무 곳이나 커서 위치
2. `Ctrl+I` (Mac: `Cmd+I`) → 커서 위에 **입력창**이 뜸
3. 다음 입력:
   ```
   위 목록에 3개 항목 더 추가해줘
   ```
4. `Enter` → 회색 미리보기 → `Accept` 클릭 (또는 `Ctrl+Enter`)

---

## 2.6 필수 단축키 정리표

| 기능 | Windows / Linux | macOS |
|------|-----------------|-------|
| 자동완성 수락 | `Tab` | `Tab` |
| 자동완성 무시 | `Esc` | `Esc` |
| 다음 자동완성 제안 | `Alt + ]` | `Option + ]` |
| Inline Chat 열기 | `Ctrl + I` | `Cmd + I` |
| Chat 사이드바 열기 | `Ctrl + Alt + I` | `Cmd + Alt + I` |
| 명령 팔레트 | `Ctrl + Shift + P` | `Cmd + Shift + P` |
| 새 파일 | `Ctrl + N` | `Cmd + N` |
| 저장 | `Ctrl + S` | `Cmd + S` |

**가장 자주 쓸 3개**: `Tab`, `Ctrl+I`, `Ctrl+Alt+I` — 이것만 손에 익히면 90% 커버됩니다.

---

## 2.7 자주 발생하는 문제와 해결

### 문제 1. 자동완성이 안 뜬다

**원인 후보와 확인 순서**
1. 라이선스 없음 → github.com/settings/copilot 확인
2. 로그인 안 됨 → 좌측 하단 계정 아이콘 확인
3. 확장이 꺼져 있음 → 우측 하단 Copilot 아이콘 클릭 → Enable
4. 파일 형식 무시됨 → 명령 팔레트 → "Copilot: Enable Completions for ..."
5. 인터넷 문제 (사내 방화벽) → 시스템 관리자에게 `*.githubcopilot.com` 허용 요청

### 문제 2. 회사 이메일로 로그인이 안 된다

- 회사가 **SAML SSO**를 쓰는 경우 개인 GitHub 계정을 회사 조직에 연결해야 합니다
- github.com 로그인 후 우측 상단 프로필 → 조직 이름 클릭 → "Configure SSO" 버튼이 있는지 확인

### 문제 3. Chat 사이드바가 안 열린다

- Copilot Chat 확장이 별도로 설치되어 있는지 확인 (Copilot과 Copilot Chat 2개)
- VS Code를 완전히 껐다가 다시 실행

---

## 2.8 (선택) 유용한 추가 확장

이 커리큘럼 진행에 필수는 아니지만, 있으면 편합니다.

| 확장 이름 | 용도 | 어떤 직군에 유용 |
|-----------|------|------------------|
| Excel Viewer | `.xlsx` 파일을 VS Code에서 미리보기 | 재무·HR·데이터 |
| Rainbow CSV | `.csv` 컬럼별 색상 강조 | 마케팅·재무·데이터 |
| Markdown All in One | Markdown 미리보기·자동완성 강화 | 전 직군 |
| SQLTools | DB 연결·쿼리 실행 | 마케팅·데이터·재무 |
| REST Client | API 호출 테스트 | 기획·PM |
| Live Server | HTML 파일 브라우저 미리보기 | 디자이너·마케터 |

각 직군 폴더 `README.md`에 **꼭 필요한 확장**이 다시 안내됩니다.

---

## 실습

### 실습 1. 위 Hello Copilot 테스트 4단계를 처음부터 끝까지 직접 완료

체크리스트:
- [ ] VS Code 설치 완료
- [ ] Copilot + Copilot Chat 확장 2개 모두 설치
- [ ] 로그인 성공 (우측 하단 Copilot 아이콘 확인)
- [ ] `hello.md`에서 Tab 자동완성 수락 성공
- [ ] Chat 사이드바에서 질문·답변 성공
- [ ] Inline Chat(`Ctrl+I`)로 텍스트 삽입 성공

### 실습 2. 나만의 첫 문서 만들기

`hello.md`를 다음 프롬프트로 완성해보세요:

```
Inline Chat 프롬프트:
"오늘의 학습 회고" 라는 제목으로 다음 섹션이 있는
Markdown 템플릿을 만들어줘:
1. 오늘 배운 것 (3개 이상 항목)
2. 어려웠던 것
3. 내일 시도할 것
```

→ 결과를 저장하고, 실제로 오늘 학습 내용을 채워보세요.

---

## 핵심 포인트

1. **확장은 2개**: GitHub Copilot + GitHub Copilot Chat (둘 다 필수)
2. **로그인 후 우측 하단 아이콘**으로 활성 상태 항상 확인
3. **필수 단축키 3개**: `Tab`, `Ctrl+I`, `Ctrl+Alt+I`
4. 문제 생기면 **로그인 → 확장 → 파일 형식 → 인터넷** 순서로 점검

---

**다음 문서**: [03-basic-usage.md](./03-basic-usage.md) — Tab / Chat / Inline Chat 실전 사용법
