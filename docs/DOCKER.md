# Docker 환경 설명

Docker 컨테이너로 Claude Code 환경을 격리하여, 공유 서버에서 개인 환경을 유지합니다.

## 이미지

- 베이스: `nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04`
- Node.js 22 + Claude Code CLI (`@anthropic-ai/claude-code`)
- uv 0.8.12 (Python 패키지 관리)
- 기본 도구: git, git-lfs, tmux, zsh, ffmpeg, openssh-client 등

## 마운트 구조

| 호스트 경로 | 컨테이너 경로 | 용도 |
|---|---|---|
| `$(pwd)` | `/workspace` | 작업 디렉토리 |
| `~/.claude` | `~/.claude` | Claude Code 인증, 설정, memory |
| `~/.gitconfig` | `~/.gitconfig` | Git 사용자 설정 |
| `~/.cache` | `~/.cache` | pip/uv 캐시 |
| `/media/data{1,2,3}` | 동일 경로 | 공유 데이터 드라이브 |

## 컨테이너 재진입

```bash
docker start -ai chan
```

## 주의사항

- `~/.claude` 디렉토리가 호스트에 없으면 먼저 `mkdir -p ~/.claude` 실행
- SSH 키가 없으면 `docker_run.sh`에서 `-v "$HOME/.ssh:..."` 줄 제거
- 포트 포워딩 필요 시 `-p 8080:8080` 옵션 추가
