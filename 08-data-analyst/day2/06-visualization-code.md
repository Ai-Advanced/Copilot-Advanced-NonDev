# 06. 시각화 코드 — matplotlib / seaborn / plotly 차트 6종

## 학습 목표

- matplotlib 기초 구조(Figure, Axes)를 이해하고 커스터마이징
- seaborn으로 상관관계/분포/시계열 차트를 빠르게 생성
- plotly로 인터랙티브 차트 생성 (대시보드 공유용)
- Copilot으로 차트 코드를 생성하고 스타일을 조정하는 방법 체득
- 실습: 대시보드용 차트 6종 완성 (KPI / 트렌드 / 분포 / 비교 / 상관 / 이탈)

**예상 소요**: 60분

---

## 6.1 라이브러리 선택 기준

| 상황 | 권장 라이브러리 |
|------|-------------|
| 정적 차트 (Jupyter, PDF 보고서용) | matplotlib / seaborn |
| 인터랙티브 차트 (공유, 슬랙, 웹 대시보드) | plotly |
| 빠른 탐색적 분析 (EDA) | seaborn (한 줄 코드) |
| 세밀한 레이아웃 제어 | matplotlib (저수준 제어) |
| BI 도구 없이 간단한 대시보드 | plotly + Dash (간단) |

**실무 조합**: EDA는 seaborn으로 빠르게, 공유·발표용은 plotly로 인터랙티브하게.

---

## 6.2 matplotlib 기초 구조

```python
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np

# 한글 폰트 설정 (Windows)
mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False  # 마이너스 기호 깨짐 방지

# 기본 구조: Figure(캔버스) + Axes(그래프 영역)
fig, ax = plt.subplots(figsize=(10, 6))

# 그래프 내용
x = [1, 2, 3, 4, 5]
y = [10, 15, 12, 20, 18]
ax.plot(x, y, color='steelblue', linewidth=2, marker='o', label='월별 가입')

# 꾸미기
ax.set_title('월별 신규 가입자 추세', fontsize=16, fontweight='bold', pad=15)
ax.set_xlabel('월', fontsize=12)
ax.set_ylabel('가입자 수', fontsize=12)
ax.legend(loc='upper left')
ax.grid(True, alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)    # 위 테두리 제거
ax.spines['right'].set_visible(False)  # 오른쪽 테두리 제거

plt.tight_layout()
plt.savefig('chart.png', dpi=150, bbox_inches='tight')  # 저장
plt.show()
```

### 서브플롯 (여러 차트 한 번에)

```python
fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle('2024년 3월 KPI 요약', fontsize=18, fontweight='bold')

# axes[행][열] 또는 axes.flatten()으로 접근
ax_top_left     = axes[0][0]
ax_top_right    = axes[0][1]
ax_bottom_left  = axes[1][0]
ax_bottom_right = axes[1][1]

plt.tight_layout(rect=[0, 0, 1, 0.95])  # suptitle 공간 확보
```

---

## 6.3 차트 1. KPI 카드 (텍스트 차트)

대시보드 상단의 KPI 요약 카드를 matplotlib으로 구현합니다.

**Copilot 프롬프트**:
```python
# matplotlib으로 KPI 요약 카드 4개를 2×2 서브플롯으로 그리는 코드.
#
# 데이터:
kpi_data = [
    {'label': '신규 가입자', 'value': '31,240',  'change': '+12.0%', 'positive': True},
    {'label': 'MRR',        'value': '$482,301', 'change': '+8.3%',  'positive': True},
    {'label': '30일 리텐션', 'value': '61.3%',   'change': '+2.6%p', 'positive': True},
    {'label': '이탈률',      'value': '8.3%',    'change': '+1.2%p', 'positive': False},
]
#
# 각 카드:
# - 배경: 연한 회색 직사각형
# - 중앙: 큰 숫자(value), fontsize=28, 굵게
# - 아래: 변화율(change), 양수=초록, 음수=빨강 (이탈률은 반대 — positive=False면 반전)
# - 상단: 레이블, fontsize=12, 회색
# - 테두리, 축 없애기
```

**완성 코드**:

```python
import matplotlib.pyplot as plt
import matplotlib as mpl

mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

kpi_data = [
    {'label': '신규 가입자', 'value': '31,240',  'change': '+12.0%', 'positive': True},
    {'label': 'MRR',        'value': '$482,301', 'change': '+8.3%',  'positive': True},
    {'label': '30일 리텐션', 'value': '61.3%',   'change': '+2.6%p', 'positive': True},
    {'label': '이탈률',      'value': '8.3%',    'change': '+1.2%p', 'positive': False},
]

fig, axes = plt.subplots(1, 4, figsize=(16, 4))
fig.suptitle('2024년 3월 핵심 KPI', fontsize=16, fontweight='bold', y=1.02)

for ax, kpi in zip(axes, kpi_data):
    ax.set_facecolor('#F8F9FA')
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')

    # 레이블
    ax.text(0.5, 0.80, kpi['label'], ha='center', va='center',
            fontsize=12, color='#6C757D')

    # 값
    ax.text(0.5, 0.50, kpi['value'], ha='center', va='center',
            fontsize=28, fontweight='bold', color='#212529')

    # 변화율
    if kpi['positive']:
        change_color = '#198754' if kpi['change'].startswith('+') else '#DC3545'
    else:
        change_color = '#DC3545' if kpi['change'].startswith('+') else '#198754'

    ax.text(0.5, 0.20, kpi['change'], ha='center', va='center',
            fontsize=14, color=change_color, fontweight='bold')

    for spine in ax.spines.values():
        spine.set_visible(False)

plt.tight_layout()
plt.savefig('kpi_cards.png', dpi=150, bbox_inches='tight')
plt.show()
```

---

## 6.4 차트 2. MRR 트렌드 (시계열 라인 차트)

**Copilot 프롬프트**:
```python
# plotly.express로 MRR 월별 트렌드 인터랙티브 라인 차트.
#
# 가상 데이터 생성:
# year_month: 2023-04 ~ 2024-03 (12개월)
# mrr: 300000에서 시작해서 성장 (약간의 노이즈 포함)
#
# 차트 요구사항:
# - 라인 차트 + 데이터 포인트 마커
# - 호버 시: 월, MRR 금액($), 전월 대비 증감율(%) 표시
# - y축: 달러 포맷 ($300,000 형식)
# - 전년 동월 대비 성장 트렌드 선 추가 (점선)
# - 타이틀: "MRR 월별 추이 (2023.04 ~ 2024.03)"
# - 색상: 라인=#2563EB, 마커=흰색 테두리
```

**완성 코드**:

```python
import pandas as pd
import numpy as np
import plotly.graph_objects as go

np.random.seed(42)
months = pd.date_range('2023-04-01', periods=12, freq='MS')
base = 300000
growth_rate = 0.05
mrr_values = [int(base * (1 + growth_rate) ** i + np.random.normal(0, 5000)) for i in range(12)]

df_mrr = pd.DataFrame({'month': months, 'mrr': mrr_values})
df_mrr['month_str'] = df_mrr['month'].dt.strftime('%Y-%m')
df_mrr['prev_mrr'] = df_mrr['mrr'].shift(1)
df_mrr['growth_pct'] = ((df_mrr['mrr'] - df_mrr['prev_mrr']) / df_mrr['prev_mrr'] * 100).round(1)

fig = go.Figure()

fig.add_trace(go.Scatter(
    x=df_mrr['month_str'],
    y=df_mrr['mrr'],
    mode='lines+markers',
    name='MRR',
    line=dict(color='#2563EB', width=2.5),
    marker=dict(size=8, color='white', line=dict(color='#2563EB', width=2)),
    customdata=df_mrr[['growth_pct']].values,
    hovertemplate=(
        '<b>%{x}</b><br>'
        'MRR: $%{y:,.0f}<br>'
        '전월 대비: %{customdata[0]:.1f}%<extra></extra>'
    )
))

fig.update_layout(
    title=dict(text='MRR 월별 추이 (2023.04 ~ 2024.03)', font=dict(size=16)),
    xaxis_title='월',
    yaxis_title='MRR (USD)',
    yaxis=dict(tickformat='$,.0f'),
    hovermode='x unified',
    plot_bgcolor='white',
    paper_bgcolor='white',
    height=400,
    showlegend=True
)
fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor='#E5E7EB')
fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor='#E5E7EB')

fig.show()
fig.write_html('mrr_trend.html')
```

---

## 6.5 차트 3. 코호트 리텐션 히트맵

**Copilot 프롬프트**:
```python
# seaborn으로 코호트 리텐션 히트맵 생성.
#
# 가상 데이터: 6개 코호트 × Month 0~6 (리텐션 비율 0~1)
# Month 0는 항상 1.0, 이후 점감
#
# 요구사항:
# - seaborn.heatmap, cmap='YlGn' (연노랑→진초록)
# - 셀 안에 % 형식 값 표시 (예: 61%)
# - 타이틀: "월별 코호트 리텐션"
# - x축: "가입 후 N개월", y축: "가입 코호트"
# - figsize=(12, 6)
# - 각 셀 폰트 크기 11
```

**완성 코드**:

```python
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib as mpl

mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

# 가상 리텐션 데이터
np.random.seed(0)
cohorts = ['2023-10', '2023-11', '2023-12', '2024-01', '2024-02', '2024-03']
months  = range(7)

retention_data = []
for i, cohort in enumerate(cohorts):
    row = [1.0]  # Month 0 = 100%
    current = 1.0
    for m in range(1, 7):
        if len(cohorts) - i <= m:
            row.append(None)  # 아직 관측 불가
        else:
            current *= np.random.uniform(0.82, 0.92)
            row.append(round(current, 3))
    retention_data.append(row)

retention_df = pd.DataFrame(
    retention_data,
    index=cohorts,
    columns=[f'Month {m}' for m in months]
).astype(float)

fig, ax = plt.subplots(figsize=(12, 6))

sns.heatmap(
    retention_df,
    ax=ax,
    cmap='YlGn',
    annot=True,
    fmt='.0%',
    linewidths=0.5,
    linecolor='white',
    cbar_kws={'label': '리텐션율', 'format': '%.0%%'},
    annot_kws={'size': 11},
    vmin=0,
    vmax=1,
    mask=retention_df.isna()
)

ax.set_title('월별 코호트 리텐션', fontsize=16, fontweight='bold', pad=15)
ax.set_xlabel('가입 후 N개월', fontsize=12)
ax.set_ylabel('가입 코호트', fontsize=12)
ax.tick_params(axis='x', rotation=0)
ax.tick_params(axis='y', rotation=0)

plt.tight_layout()
plt.savefig('cohort_retention_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()
```

---

## 6.6 차트 4. 퍼널 차트 (비교 막대)

**Copilot 프롬프트**:
```python
# plotly.graph_objects로 수평 퍼널 막대 차트.
#
# 가상 데이터:
funnel_data = [
    {'stage': 'Landing View',       'users': 100000},
    {'stage': 'Signup Start',       'users': 42300},
    {'stage': 'Signup Complete',    'users': 31200},
    {'stage': 'Trial Start',        'users': 18900},
    {'stage': 'Subscription Start', 'users': 8240},
]
#
# 요구사항:
# - 수평 막대 차트
# - 각 막대 오른쪽에 사용자 수 + 직전 단계 대비 전환율 레이블
# - 색상: 단계가 내려갈수록 파란색이 진해지는 그라데이션
# - 타이틀: "가입 퍼널 전환율 분析"
# - 호버: 단계명, 사용자 수, 전환율
```

**완성 코드**:

```python
import plotly.graph_objects as go
import pandas as pd

funnel_data = [
    {'stage': 'Landing View',       'users': 100000},
    {'stage': 'Signup Start',       'users': 42300},
    {'stage': 'Signup Complete',    'users': 31200},
    {'stage': 'Trial Start',        'users': 18900},
    {'stage': 'Subscription Start', 'users': 8240},
]

df_funnel = pd.DataFrame(funnel_data)
df_funnel['prev_users'] = df_funnel['users'].shift(1).fillna(df_funnel['users'].iloc[0])
df_funnel['conv_rate'] = (df_funnel['users'] / df_funnel['prev_users'] * 100).round(1)
df_funnel.loc[0, 'conv_rate'] = 100.0

colors = ['#1e3a5f', '#1a5276', '#1f618d', '#2874a6', '#3498db']

fig = go.Figure(go.Bar(
    x=df_funnel['users'],
    y=df_funnel['stage'],
    orientation='h',
    marker_color=colors,
    text=[f"{row['users']:,}명  ({row['conv_rate']:.0f}%)" for _, row in df_funnel.iterrows()],
    textposition='outside',
    hovertemplate='<b>%{y}</b><br>사용자: %{x:,}명<extra></extra>'
))

fig.update_layout(
    title=dict(text='가입 퍼널 전환율 分析', font=dict(size=16)),
    xaxis_title='사용자 수',
    yaxis=dict(autorange='reversed'),
    plot_bgcolor='white',
    height=350,
    margin=dict(l=150, r=120)
)
fig.update_xaxes(showgrid=True, gridcolor='#E5E7EB')

fig.show()
fig.write_html('funnel_chart.html')
```

---

## 6.7 차트 5. 상관관계 히트맵 (seaborn)

**Copilot 프롬프트**:
```python
# seaborn으로 수치형 컬럼 간 상관관계 히트맵.
#
# 가상 데이터: 500명 사용자
# 컬럼: tenure_days, login_count, feature_use_count, payment_count, total_amount, support_tickets
# (일부 컬럼은 서로 높은 상관관계를 갖도록 설계)
#
# 요구사항:
# - 상삼각 마스킹 (대각선 포함, 하삼각만 표시)
# - 상관계수 값 셀 안에 표시 (소수점 2자리)
# - cmap: 'RdBu_r' (빨강=양의 상관, 파랑=음의 상관)
# - 통계적 유의성(p<0.05) 없는 셀은 회색으로 표시 (scipy 활용)
# - figsize=(10, 8)
```

**완성 코드**:

```python
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from scipy import stats
import matplotlib as mpl

mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

np.random.seed(42)
n = 500
tenure = np.random.exponential(200, n)
logins = tenure * 0.3 + np.random.normal(0, 20, n)
features = logins * 1.5 + np.random.normal(0, 15, n)
payments = tenure * 0.05 + np.random.normal(0, 5, n)
amount = payments * 20 + np.random.normal(0, 50, n)
tickets = np.random.poisson(2, n)

df_corr = pd.DataFrame({
    '구독 기간(일)':  tenure.clip(0),
    '로그인 횟수':    logins.clip(0),
    '기능 사용 횟수': features.clip(0),
    '결제 횟수':     payments.clip(0),
    '총 결제 금액':  amount.clip(0),
    '지원 티켓':     tickets
})

corr_matrix = df_corr.corr()

# p-value 행렬 계산
n_cols = len(df_corr.columns)
p_matrix = np.zeros((n_cols, n_cols))
for i in range(n_cols):
    for j in range(n_cols):
        if i != j:
            _, p = stats.pearsonr(df_corr.iloc[:, i].dropna(), df_corr.iloc[:, j].dropna())
            p_matrix[i, j] = p
        else:
            p_matrix[i, j] = 0

mask_upper = np.triu(np.ones_like(corr_matrix, dtype=bool))
mask_insig = (p_matrix >= 0.05) & ~mask_upper

fig, ax = plt.subplots(figsize=(10, 8))

sns.heatmap(
    corr_matrix,
    ax=ax,
    mask=mask_upper,
    cmap='RdBu_r',
    vmin=-1, vmax=1,
    annot=True, fmt='.2f',
    linewidths=0.5,
    linecolor='white',
    annot_kws={'size': 10},
    square=True
)

ax.set_title('사용자 행동 지표 상관관계\n(p≥0.05 셀 제외)', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig('correlation_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()
```

---

## 6.8 차트 6. 이탈 예측 신호 시각화 (분포 비교)

**Copilot 프롬프트**:
```python
# seaborn.violinplot으로 이탈 vs 유지 그룹의 행동 지표 분포 비교.
#
# 가상 데이터: 1,000명 (churned=0/1)
# 비교 지표: 이탈 30일 전 로그인 횟수
#
# 요구사항:
# - violin plot + 내부에 boxplot (inner='box')
# - 2개 그룹(이탈/유지) 색상: 이탈=salmon, 유지=steelblue
# - 각 그룹의 중앙값 수평선 추가 (점선)
# - 중앙값 값을 차트 안에 텍스트로 표시
# - 타이틀: "이탈 전 30일 로그인 횟수 분포: 이탈 vs 유지 그룹"
# - x축 레이블: "이탈 여부 (0=유지, 1=이탈)", y축: "30일 로그인 횟수"
# - 통계적 유의성 표시 (Mann-Whitney U test p-value 차트 상단에)
```

**완성 코드**:

```python
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from scipy import stats
import matplotlib as mpl

mpl.rcParams['font.family'] = 'Malgun Gothic'
mpl.rcParams['axes.unicode_minus'] = False

np.random.seed(42)
n = 1000
churned = np.random.binomial(1, 0.3, n)  # 30% 이탈률

logins = np.where(
    churned == 1,
    np.random.poisson(3, n),   # 이탈 그룹: 평균 3회
    np.random.poisson(12, n)   # 유지 그룹: 평균 12회
)

df_churn = pd.DataFrame({'churned': churned, 'logins_30d': logins})
df_churn['group'] = df_churn['churned'].map({0: '유지', 1: '이탈'})

medians = df_churn.groupby('group')['logins_30d'].median()
stat, p_value = stats.mannwhitneyu(
    df_churn[df_churn['churned'] == 0]['logins_30d'],
    df_churn[df_churn['churned'] == 1]['logins_30d']
)

fig, ax = plt.subplots(figsize=(9, 6))

palette = {'유지': 'steelblue', '이탈': 'salmon'}
sns.violinplot(
    data=df_churn,
    x='group',
    y='logins_30d',
    hue='group',
    palette=palette,
    inner='box',
    ax=ax,
    legend=False
)

for i, (group, median) in enumerate(medians.items()):
    ax.axhline(y=median, xmin=i*0.5+0.05, xmax=i*0.5+0.45, color='black', linestyle='--', linewidth=1.5)
    ax.text(i, median + 0.5, f'중앙값: {median:.0f}회', ha='center', fontsize=10, color='black')

sig = '***' if p_value < 0.001 else ('**' if p_value < 0.01 else ('*' if p_value < 0.05 else 'n.s.'))
ax.set_title(
    f'이탈 전 30일 로그인 횟수 분포: 이탈 vs 유지 그룹\n(Mann-Whitney U, p={p_value:.4f} {sig})',
    fontsize=13, fontweight='bold'
)
ax.set_xlabel('그룹', fontsize=12)
ax.set_ylabel('30일 로그인 횟수', fontsize=12)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('churn_signal_violin.png', dpi=150, bbox_inches='tight')
plt.show()
```

---

## 6.9 Copilot으로 차트 스타일 개선하기

기본 차트가 생성된 후 스타일을 개선할 때는 후속 프롬프트를 씁니다.

### 자주 쓰는 스타일 개선 프롬프트

```python
# 기존 차트 코드에 아래 요구사항 반영해줘:
# 1. 폰트 크기: 제목 16, 축 레이블 12, 틱 10
# 2. 배경 흰색, 격자선 연한 회색(#E5E7EB), 위/오른쪽 테두리 제거
# 3. 색상을 회사 브랜드 팔레트로: 기본 #2563EB, 보조 #64748B
# 4. 각 데이터 포인트 위에 값 레이블 추가
# 5. 범례 위치: 오른쪽 상단 외부
```

### 발표용 vs 탐색용 스타일

```python
# 발표/임원 공유용 스타일
def presentation_style(ax):
    ax.set_facecolor('white')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.grid(True, alpha=0.3, linestyle='--', color='#E5E7EB')
    ax.tick_params(labelsize=10)
    return ax

# 탐색용 (Jupyter 내부, 빠른 확인)
import seaborn as sns
sns.set_theme(style='whitegrid', palette='muted')
```

---

## 실습: 6종 차트 완성 체크리스트

| 차트 | 라이브러리 | 완료 |
|------|----------|------|
| KPI 카드 4개 | matplotlib | [ ] |
| MRR 트렌드 (인터랙티브) | plotly | [ ] |
| 코호트 리텐션 히트맵 | seaborn | [ ] |
| 퍼널 차트 | plotly | [ ] |
| 상관관계 히트맵 | seaborn | [ ] |
| 이탈 신호 바이올린 플롯 | seaborn | [ ] |

---

## 핵심 포인트

1. **라이브러리 선택**: 탐색/보고서 = seaborn, 공유/인터랙티브 = plotly
2. **SettingWithCopyWarning**: 차트용 데이터 준비 시에도 `.copy()` 습관화
3. **한글 폰트**: `mpl.rcParams['font.family'] = 'Malgun Gothic'` (Windows). 축 레이블 깨지면 이것부터 확인
4. **Copilot 스타일 개선**: 차트 코드 생성 후 "위 코드에 [요구사항] 반영" 후속 프롬프트로 점진적 개선
5. **저장**: matplotlib은 `savefig()`, plotly는 `write_html()` (인터랙티브 유지)

---

**다음 챕터**: [07-dashboard-spec-and-storytelling.md](./07-dashboard-spec-and-storytelling.md) — 대시보드 스펙 문서화 + 인사이트 스토리텔링
