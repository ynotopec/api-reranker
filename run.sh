#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
VENV_DIR="${VENV_DIR:-$HOME/venv/$PROJECT_NAME}"

HOST="${1:-${HOST:-0.0.0.0}}"
PORT="${2:-${PORT:-8000}}"

if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
fi

MODEL_ID="${MODEL_ID:-BAAI/bge-reranker-v2-m3}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-}"
MODEL_ALIAS="${MODEL_ALIAS:-}"

API_KEY="${API_KEY:-}"

DTYPE="${DTYPE:-auto}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.25}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-16}"
MAX_NUM_BATCHED_TOKENS="${MAX_NUM_BATCHED_TOKENS:-16384}"

# Par défaut, Hugging Face utilise son cache standard (~/.cache/huggingface).
# Définis HF_HOME ou HUGGINGFACE_HUB_CACHE dans .env uniquement pour le surcharger.
if [[ -n "${HF_HOME:-}" ]]; then
  export HF_HOME
fi
if [[ -n "${HUGGINGFACE_HUB_CACHE:-}" ]]; then
  export HUGGINGFACE_HUB_CACHE
fi
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

export FLASHINFER_DISABLE_VERSION_CHECK="${FLASHINFER_DISABLE_VERSION_CHECK:-0}"
export VLLM_WORKER_MULTIPROC_METHOD="${VLLM_WORKER_MULTIPROC_METHOD:-spawn}"

if [[ ! -d "$VENV_DIR" ]]; then
  echo "ERROR: venv not found: $VENV_DIR"
  echo "Run ./install.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

ARGS=(
  --model "$MODEL_ID"
  --host "$HOST"
  --port "$PORT"
  --runner pooling
  --dtype "$DTYPE"
  --max-model-len "$MAX_MODEL_LEN"
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"
  --max-num-seqs "$MAX_NUM_SEQS"
  --max-num-batched-tokens "$MAX_NUM_BATCHED_TOKENS"
  --trust-remote-code
)

if [[ -n "$SERVED_MODEL_NAME" || -n "$MODEL_ALIAS" ]]; then
  SERVED_MODEL_NAMES=("${SERVED_MODEL_NAME:-$MODEL_ID}")
  if [[ -n "$MODEL_ALIAS" && "$MODEL_ALIAS" != "${SERVED_MODEL_NAMES[0]}" ]]; then
    SERVED_MODEL_NAMES+=("$MODEL_ALIAS")
  fi
  ARGS+=(--served-model-name "${SERVED_MODEL_NAMES[@]}")
fi

if [[ -n "$API_KEY" ]]; then
  ARGS+=(--api-key "$API_KEY")
fi

if [[ "${ENFORCE_EAGER:-1}" == "1" ]]; then
  ARGS+=(--enforce-eager)
fi

if [[ "${DISABLE_LOG_REQUESTS:-1}" == "1" ]]; then
  ARGS+=(--no-enable-log-requests)
fi

echo "==> Starting vLLM reranker"
echo "    project: $PROJECT_NAME"
echo "    venv:    $VENV_DIR"
echo "    model:   $MODEL_ID"
if [[ -n "$SERVED_MODEL_NAME" ]]; then
  echo "    name:    $SERVED_MODEL_NAME"
fi
if [[ -n "$MODEL_ALIAS" ]]; then
  echo "    alias:   $MODEL_ALIAS"
fi
echo "    url:     http://$HOST:$PORT"
echo "    api:     POST /score"
echo "    mem:     GPU_MEMORY_UTILIZATION=$GPU_MEMORY_UTILIZATION"
echo "    limits:  MAX_MODEL_LEN=$MAX_MODEL_LEN MAX_NUM_SEQS=$MAX_NUM_SEQS MAX_NUM_BATCHED_TOKENS=$MAX_NUM_BATCHED_TOKENS"
echo

exec python -m vllm.entrypoints.openai.api_server "${ARGS[@]}"
