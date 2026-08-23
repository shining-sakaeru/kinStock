# KinStock - 테마주 인물 네트워크 연관성 기반 주식 추천 시스템

오픈소스 기술 스택(Python FastAPI, NetworkX/Neo4j, Flutter)만을 활용하여 정·재계 인물 네트워크(학연, 지연, 혈연, 직장동기 등)를 분석하고, 가중치 감가율(Decay Rate) 기반 테마주를 추천하는 풀스택 애플리케이션입니다.

---

## 🏛 아키텍처 및 핵심 로직

### 1. N-depth 가중치 감가(Decay Rate) 알고리즘
- **단일 경로 점수**: $Score(P) = \left( \prod_{i=1}^{L} w(e_i) \right) \times (\lambda)^{L - 1}$ ($\lambda = 0.80$, 다단계 깊이에 따른 지수 감가)
- **다중 경로 결합**: 동일 기업으로 연결되는 여러 경로가 존재할 경우 독립 확률 결합(Dampened Probabilistic Union) 모델을 적용하여 $0 \sim 100$점 연관도 점수 환산.
- **관계 가중치 정의**:
  - `혈연관계` (0.95), `인척관계` (0.85), `정치캠프` (0.80), `직장동기` (0.75), `고교동문` (0.65), `대학동문` (0.55), `지연연관` (0.40)
  - `최대주주` (0.95), `창업주` (0.90), `대표/임원` (0.85), `사외이사` (0.65), `정책수혜` (0.50)

### 2. 하이브리드 UI/UX Flow (Flutter)
- **Main Screen (분할 화면)**:
  - **[상단 30%]**: 선택된 중심 인물 기준 상위 3~5개 핵심 연결을 직관적으로 보여주는 방사형 미니 그래프 (`CustomPainter` 60fps 애니메이션)
  - **[하단 70%]**: 연관도 점수 내림차순 정렬 랭킹 테이블 (종목명, 티커, 등락률 컬러링, 시가총액, `[고교동문 ➔ 대표이사]` 연관성 뱃지, 실시간 검색/필터)
- **Detail Screen (Deep Dive Mindmap)**:
  - 메인 화면 리스트에서 특정 기업 탭 시 이동
  - 중심 인물부터 타겟 기업까지의 연결고리를 전체화면 인터랙티브 네트워크 그래프로 렌더링 (`graphview` + `InteractiveViewer` 줌/팬 지원)

---

## 🚀 실행 가이드

### 1. 백엔드 (FastAPI & Graph Engine)
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- Swagger API 문서: `http://localhost:8000/docs`
- Neo4j Cypher 스크립트 추출: `http://localhost:8000/api/v1/export/neo4j-cypher`

### 2. 백엔드 단위 테스트
```bash
cd backend
PYTHONPATH=. ./venv/bin/pytest tests
```

### 3. 프론트엔드 (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome # 또는 macOS / Android / iOS
```

### 4. 프론트엔드 위젯 테스트
```bash
cd frontend
flutter test
```
