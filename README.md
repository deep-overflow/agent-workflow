# agent-workflow

여러 서버에서 Claude Code 환경을 빠르게 세팅하기 위한 자동화 프로젝트.

## Quick Start

레포를 클론한 후, 아래 순서대로 실행하세요.

```bash
# 1. Docker 이미지 빌드
docker build -t claude-agent docker/

# 2. 컨테이너 실행
bash scripts/docker_run.sh

# 3. (컨테이너 내) Claude Code 로그인
claude login

# 4. (컨테이너 내) Claude Code statusline 세팅
#    docs/SETTINGS.md의 지시를 따르거나 Claude Code에게 읽게 하세요
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
│   ├── DOCKER.md           # Docker 환경 세팅 가이드
│   └── SETTINGS.md         # Claude Code 설정 지시서
└── README.md
```

## Docs

| 문서 | 참고 시점 |
|---|---|
| [docs/DOCKER.md](docs/DOCKER.md) | 새 서버에서 Docker 환경을 처음 세팅할 때 |
| [docs/SETTINGS.md](docs/SETTINGS.md) | 컨테이너 안에서 Claude Code statusline 등 설정을 적용할 때 |
| [docs/RULES.md](docs/RULES.md) | Claude Code 연구 워크플로우 규칙을 `~/.claude/CLAUDE.md`에 적용할 때 |
