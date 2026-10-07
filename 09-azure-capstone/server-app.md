# 선택 심화 — Python 보고서를 App Service에서 실행

[공통 과정](README.md)을 마친 뒤, 서버가 필요한 직군만 선택합니다.
이 과정은 **가상 부서 매출을 Python에서 계산하는 읽기 전용 앱**입니다.
실제 파일 업로드·ERP 연결·메일 발송·예약 결산은 포함하지 않습니다.

## 강사가 먼저 준비

- 운영 환경과 분리된 교육용 Linux App Service, Python 3.12 런타임, 승인된 요금제
- 학생별 정확한 사이트·그룹과 배포 권한; 공유 운영 앱 사용 금지
- 앱 설정 `SCM_DO_BUILD_DURING_DEPLOYMENT=true`
- 시작 명령: `gunicorn --bind=0.0.0.0:8000 app:app`
- 가상 보고서의 공개 허용 또는 조직에 맞는 접근 제어
- App Service Plan은 앱을 중지해도 비용이 남을 수 있음을 안내

기본 Static Web Apps 배포 스크립트를 사용하지 않습니다.
학생에게 리소스 생성·SKU 변경을 AI에게 일임하도록 안내하지 않습니다.

## 1. 로컬 실행·검증

Python 3.12가 설치된 터미널에서 저장소 루트 기준:

```powershell
Set-Location .\09-azure-capstone\examples\server-report
python -m unittest -v
python app.py
```

`http://127.0.0.1:8000`을 열어 전체 합계 250만원, 영업 120만원, 마케팅 80만원을 확인합니다.
선택한 부서가 URL 쿼리로 전달되고 서버가 HTML을 다시 만드는지 확인합니다.
로컬 미리보기는 `Ctrl+C`로 종료합니다. 기본 라이브러리 미리보기 서버를 Azure 운영 시작 명령으로 사용하지 않습니다.

```text
app.py는 가상 데이터로 만드는 읽기 전용 WSGI 보고서야.
부서별 예산 대비 차이를 표시하도록 확장하고 테스트도 추가해줘.
실제 파일 업로드·DB·개인정보는 넣지 마.
잘못된 부서 입력은 오류를 명확히 반환하고 숫자는 테스트로 검증해.
```

## 2. 검토한 파일만 ZIP으로 배포

저장소 루트로 돌아와 아래 두 파일만 압축합니다. ZIP 최상위에 `app.py`, `requirements.txt`가 있어야 합니다.

```powershell
Compress-Archive -LiteralPath `
  .\09-azure-capstone\examples\server-report\app.py,`
  .\09-azure-capstone\examples\server-report\requirements.txt `
  -DestinationPath .\09-azure-capstone\server-report.zip
```

기존 ZIP이 있으면 파일을 확인하고 새 버전 이름을 사용합니다. 저장소 전체·설정 파일·테스트 로그를 압축하지 않습니다.
아래 값은 강사의 배정 정보로만 입력합니다.

```powershell
$subscription = "<교육 구독 ID>"
$group = "<교육 리소스 그룹>"
$app = "<배정받은 App Service 이름>"
az account show --subscription $subscription --query "{subscription:id,tenant:tenantId}" -o table
az webapp show --subscription $subscription --resource-group $group --name $app --query "{id:id,state:state,host:defaultHostName}" -o table
```

강사와 대상을 확인한 뒤에만 실행:

```powershell
az webapp deploy --subscription $subscription --resource-group $group `
  --name $app --type zip --src-path .\09-azure-capstone\server-report.zip
if ($LASTEXITCODE -ne 0) { throw "배포 실패: 오류를 확인하고 강사에게 알리세요." }
```

배포 URL에서 합계·필터·잘못된 입력을 다시 확인합니다. `lab-v2` 문구로 수정한 ZIP을 새로 만들어 재배포합니다.
화면만 뜨고 Python 필터가 작동하지 않으면 완료가 아닙니다.

## 종료와 운영 전환

강사가 해당 앱과 전용 Plan의 보관·삭제 여부를 확인합니다. 공유 Plan은 삭제하지 않습니다.
실제 업무에 적용하려면 인증·권한·데이터 보관·백업·감사·입력 검증·장애 대응을 별도로 설계해야 합니다.
다음 단계는 Track 4에서 이 앱에 CI/CD와 운영 절차를 붙이는 것입니다.
