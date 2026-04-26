# agent-workflow

여러 서버에서 Claude Code 환경을 빠르게 세팅하기 위한 자동화 프로젝트.

## Quick Start

레포를 클론한 후, 아래 순서대로 실행하세요.

```bash
# 1. Docker 이미지 빌드
docker build -t chan docker/

# .gitconfig 파일과 .claude 폴더 생성

# 2. 컨테이너 실행
bash scripts/docker_run.sh

# 3. (컨테이너 내) Claude Code 로그인
claude login

# 4. (컨테이너 내) Claude Code에게 환경 세팅 지시
#    docs/SETTINGS.md를 읽게 하면 자동으로 수행합니다
```

## 구조

```
agent-workflow/
├── docker/
│   ├── Dockerfile          # CUDA + Node.js + Claude Code 이미지
│   └── entrypoint.sh       # 호스트 UID/GID 매핑 + gosu
├── scripts/
│   ├── docker_run.sh       # 컨테이너 실행 (GPU, 볼륨 마운트)
│   └── statusline.sh       # Claude Code 커스텀 statusline
├── docs/
│   ├── DOCKER.md           # Docker 환경 설명
│   ├── SETTINGS.md         # Claude Code 설정 지시서
│   └── RULES.md            # Claude Code 연구 워크플로우 규칙
└── README.md
```

## Docs

| 문서 | 참고 시점 |
|---|---|
| [docs/DOCKER.md](docs/DOCKER.md) | Docker 이미지/컨테이너 구성을 이해할 때 |
| [docs/SETTINGS.md](docs/SETTINGS.md) | 컨테이너 안에서 Claude Code에게 환경 세팅을 지시할 때 |
| [docs/RULES.md](docs/RULES.md) | Claude Code 연구 워크플로우 규칙을 확인/수정할 때 |
