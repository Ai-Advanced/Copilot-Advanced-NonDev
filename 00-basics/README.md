# 00. 공통 기초 (모든 직군 필수 선행)

> 이 폴더는 어떤 직군을 학습하든 **반드시 먼저 완료해야 하는** 공통 기초입니다.
> 소요 시간: 약 **60~90분**

---

## 학습 목표

이 챕터를 마치면 여러분은:

- ✅ GitHub Copilot이 **비개발자에게** 왜 유용한지 설명할 수 있다
- ✅ VS Code + Copilot 확장 설치를 스스로 완료할 수 있다
- ✅ Copilot의 3가지 상호작용 방식(**Tab, Chat, Inline Chat**)을 구분해서 쓸 수 있다
- ✅ **좋은 프롬프트와 나쁜 프롬프트의 차이**를 알고 실전에 적용할 수 있다
- ✅ Markdown / CSV / JSON / SQL 파일이 무엇인지, 왜 다루게 되는지 안다

---

## 학습 순서

| 순서 | 파일 | 소요 시간 | 내용 |
|------|------|-----------|------|
| 1 | [01-copilot-overview.md](./01-copilot-overview.md) | 15분 | Copilot이란? 비개발자 관점의 활용 시나리오 5선 |
| 2 | [02-installation.md](./02-installation.md) | 15분 | VS Code + Copilot 확장 설치, 로그인, 첫 테스트 |
| 3 | [03-basic-usage.md](./03-basic-usage.md) | 20분 | Tab / Chat / Inline Chat 사용법과 구분 기준 |
| 4 | [04-prompt-basics.md](./04-prompt-basics.md) | 20분 | 3S 원칙, BAD vs GOOD, 상황별 템플릿 5개 |
| 5 | [05-file-types-nondev.md](./05-file-types-nondev.md) | 15분 | 비개발자가 만나는 파일 형식: `.md`, `.csv`, `.json`, `.sql`, `.yaml` |

---

## 완료 체크리스트

이 5개 문서를 모두 마쳤다면, 다음이 가능해야 합니다:

- [ ] VS Code에서 새 파일을 만들고 Copilot이 자동완성을 제안하는 것을 확인
- [ ] `Ctrl+I`(Windows) 또는 `Cmd+I`(Mac)로 Inline Chat을 띄울 수 있음
- [ ] Copilot Chat 사이드바를 열고 아무 질문이나 던져 답을 받을 수 있음
- [ ] 프롬프트에 **맥락(파일, 목적, 형식)** 3가지를 항상 포함하는 습관이 잡힘
- [ ] `.md` 파일을 만들어 간단한 문서 하나를 Copilot 도움으로 작성 완료

---

## 다음 단계

공통 기초를 완료했다면, [루트 README](../README.md#커리큘럼-지도)로 돌아가 **자기 직군 폴더**로 이동하세요.

## FAQ

**Q. Copilot Business/Enterprise/Individual 중 뭐가 필요한가요?**
A. Individual($10/월)이면 이 커리큘럼의 모든 실습이 가능합니다. 회사에서 라이선스를 받았다면 그것을 쓰세요.

**Q. VS Code 대신 다른 편집기(Cursor, JetBrains 등)를 써도 되나요?**
A. 됩니다. 다만 이 커리큘럼의 스크린샷·단축키는 VS Code 기준입니다. Cursor는 90% 동일합니다.

**Q. Copilot이 한국어를 잘 이해하나요?**
A. 매우 잘 이해합니다. 프롬프트를 한국어로 써도 됩니다. 다만 **파일명·변수명·기술 용어는 영어**로 유지하는 것이 결과가 안정적입니다.

**Q. AI가 만든 내용을 그대로 써도 되나요?**
A. **절대 안 됩니다.** AI는 그럴듯한 거짓말(hallucination)을 합니다. 반드시 검토·검증하는 습관이 이 커리큘럼 전체를 관통하는 원칙입니다.
