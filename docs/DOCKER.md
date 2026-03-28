# Docker 환경 세팅 가이드

Docker 컨테이너로 Claude Code 환경을 격리하여, 공유 서버에서 개인 환경을 유지합니다.

## 빌드

```bash
docker build -t claude-agent docker/
```

## 실행

```bash
bash scripts/docker_run.sh
```

컨테이너 이름은 `claude-{username}`으로 자동 설정됩니다.

## 마운트 구조

| 호스트 경로 | 컨테이너 경로 | 용도 |
|---|---|---|
| `~/.claude` | `~/.claude` | Claude Code 인증, 설정, memory |
| `~/.ssh` | `~/.ssh` (읽기전용) | GitHub SSH 키 |
| `~/.gitconfig` | `~/.gitconfig` (읽기전용) | Git 사용자 설정 |
| `~/.cache` | `~/.cache` | pip/uv 캐시 |
| `$(pwd)` | `/workspace` | 작업 디렉토리 |

## 포함된 도구

- **Claude Code CLI** (npm)
- **Node.js 22**
- **CUDA 12.8 + cuDNN** (GPU 학습)
- **uv** (Python 패키지 관리)
- **git, tmux, zsh, ffmpeg** 등 기본 도구

## 컨테이너 재진입

```bash
docker start -ai claude-$(whoami)
```

## 주의사항

- `~/.claude` 디렉토리가 호스트에 없으면 먼저 `mkdir -p ~/.claude` 실행
- SSH 키가 없으면 `docker_run.sh`에서 `-v "$HOME/.ssh:..."` 줄 제거
- 포트 포워딩 필요 시 `-p 8080:8080` 옵션 추가
