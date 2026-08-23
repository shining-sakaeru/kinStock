# 🚀 Oracle Cloud Always Free (ARM64) 5분 초간단 배포 가이드

본 가이드는 클라우드 인프라 지식이 없어도 **오라클 클라우드 Always Free ARM VM(4 OCPU, 24GB RAM - 평생 무료)**을 생성하고, 명령어 1~2줄로 KinStock 전체 스택(Neo4j, FastAPI, Flutter Web, Cloudflare Tunnel)을 배포하여 **공개 HTTPS 링크**를 얻는 전 과정을 안내합니다.

---

## 📌 전체 진행 요약 (5분 소요)
1. **[1단계]** 오라클 클라우드 콘솔에서 **평생 무료 ARM VM (Ampere 4코어 24GB)** 생성 & SSH Key 다운로드 (2분)
2. **[2단계]** 터미널/PowerShell에서 VM으로 **SSH 원격 접속** (1분)
3. **[3단계]** KinStock 저장소 클론 및 **`./deploy.sh` 실행** (2분)
4. **[완료]** 터미널에 자동 출력되는 **공개 HTTPS URL (`https://*.trycloudflare.com`)**을 팀원/테스터에게 공유!

---

## 🛠️ Step 1. Oracle Cloud Always Free 인스턴스 생성 (2분)

1. **[Oracle Cloud 콘솔](https://cloud.oracle.com/) 로그인**
2. 메인 화면에서 **[Create a VM instance (인스턴스 생성)]** 클릭
3. **핵심 설정 항목 (반드시 아래대로 선택)**:
   - **이름 (Name)**: `kinstock-server`
   - **이미지 및 셰이프 (Image and Shape)**:
     - **Image**: `Ubuntu 22.04` 또는 `Ubuntu 24.04` (Canonical Ubuntu 선택)
     - **Shape**: **[Change Shape (셰이프 변경)]** 클릭 $\rightarrow$ **`Ampere (ARM)`** 탭 선택 $\rightarrow$ **`VM.Standard.A1.Flex`** 선택
     - **스펙 슬라이더 설정**:
       - **OCPU 수**: `4` (Always Free 최대치)
       - **메모리(RAM)**: `24` GB (Always Free 최대치)
       - *(Always Free Eligible 뱃지가 표시되는지 확인)*
   - **네트워킹 (Networking)**:
     - 기본값 유지 (`Create new VCN` 및 `Assign a public IPv4 address (공용 IPv4 할당)` 체크)
   - **SSH 키 추가 (Add SSH keys) - [가장 중요]**:
     - **[Save private key (프라이빗 키 저장)]** 버튼 클릭 $\rightarrow$ `ssh-key-*.key` 파일을 컴퓨터의 다운로드 폴더에 안전하게 저장합니다.
4. 하단 **[Create (생성)]** 버튼 클릭!
   - 1~2분 후 인스턴스 상태가 노란색(PROVISIONING)에서 **초록색(RUNNING)**으로 변경됩니다.
   - 화면에 표시된 **`Public IP Address (공용 IP 주소)`** (예: `150.230.12.34`)를 복사합니다.

---

## 💻 Step 2. 내 컴퓨터 터미널에서 SSH 접속하기 (1분)

내 컴퓨터(Mac / Windows / Linux)의 터미널(또는 PowerShell)을 열고 실행합니다:

```bash
# 1. 다운로드 받은 SSH 키 파일이 있는 폴더로 이동 (예: Downloads)
cd ~/Downloads

# 2. 키 파일 권한 설정 (Mac/Linux 필수)
chmod 400 ssh-key-*.key

# 3. 오라클 인스턴스 SSH 접속 (IP 부분에 본인의 Public IP 입력)
ssh -i ssh-key-*.key ubuntu@<본인의_오라클_공용_IP>
```

> **접속 확인**: `ubuntu@kinstock-server:~$` 프롬프트가 뜨면 접속 성공입니다!

---

## 🐳 Step 3. KinStock 원클릭 배포 스크립트 실행 (2분)

서버 터미널에 다음 명령어를 복사하여 붙여넣고 엔터만 치면 됩니다:

```bash
# 1. 저장소 클론 및 폴더 이동
git clone https://github.com/your-org/KinStock.git
cd KinStock

# 2. 실행 권한 부여 및 원클릭 자동 배포 실행
chmod +x deploy.sh
./deploy.sh
```

### `deploy.sh`가 알아서 수행하는 작업:
- 🔄 Ubuntu ARM64용 Docker 및 Docker Compose 자동 설치
- 📦 Flutter Web 최적화 릴리스 빌드
- 🐳 Neo4j(Graph DB 4GB Heap), FastAPI Backend, Nginx Web, Cloudflare Tunnel 컨테이너 자동 기동
- 🌐 Cloudflare Tunnel 무료 HTTPS 도메인 자동 생성

---

## 🎉 Step 4. 배포 완료 및 외부 접속 테스트

스크립트가 끝나면 터미널에 아래와 같이 **공개 HTTPS 접속 URL**이 즉시 출력됩니다:

```
======================================================================
   🎉 KinStock All-in-One Service Successfully Deployed!             
======================================================================

🌐 Public HTTPS URL (Cloudflare Tunnel):
   👉 https://prompt-random-sample.trycloudflare.com

📍 Local & Management Endpoints:
   - 📱 Frontend Web App:     http://localhost:80 (or http://localhost:3000)
   - ⚙️  FastAPI Swagger Docs: http://localhost:8000/docs (or http://localhost/docs)
   - 🗄️  Neo4j Browser:        http://localhost:7474 (user: neo4j, pass: kinstock2024!)

📋 Management Commands:
   - 실시간 로그 확인:        docker compose logs -f
   - 터널 URL 다시 확인:      docker compose logs cloudflare-tunnel
   - 전체 서비스 중지:        docker compose down
   - 전체 서비스 재시작:      docker compose restart
======================================================================
```

> **꿀팁**: 별도의 방화벽(Ingress Rule/Security List) 포트 개방이나 유료 도메인 구매가 전혀 필요 없습니다. `Cloudflare Tunnel`이 아웃바운드 터널을 뚫어주므로, 출력된 `https://*.trycloudflare.com` 링크를 테스터나 모바일 폰 브라우저에 바로 전달하여 접속하시면 됩니다!
