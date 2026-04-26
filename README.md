# api-reranker

Serveur vLLM CUDA 13 pour `BAAI/bge-reranker-v2-m3` ou un fork compatible, exposé via `/score`.

## Installation

```bash
chmod +x install.sh run.sh
./install.sh

cp .env.example .env
nano .env
````

Le venv est créé automatiquement dans :

```bash
~/venv/<basename project dir>
```

Exemple :

```bash
/home/ailab/api-reranker
/home/ailab/venv/api-reranker
```

## Lancement

```bash
./run.sh
```

ou :

```bash
./run.sh 0.0.0.0 8000
```

## Test santé

```bash
curl -s http://127.0.0.1:8000/health
```

## Test /score

```bash
curl -s http://127.0.0.1:8000/score \
  -H 'Authorization: Bearer change-me' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "queries": "capitale de la France",
    "documents": [
      "Paris est la capitale de la France.",
      "CUDA accélère les calculs GPU."
    ]
  }' | jq
```

## Réglage mémoire

Si vLLM affiche :

```text
Free memory on device cuda:0 (...) is less than desired GPU memory utilization
```

baisse dans `.env` :

```bash
GPU_MEMORY_UTILIZATION=0.20
MAX_MODEL_LEN=2048
MAX_NUM_SEQS=8
MAX_NUM_BATCHED_TOKENS=8192
```

Si tu as assez de VRAM libre, tu peux monter :

```bash
GPU_MEMORY_UTILIZATION=0.50
MAX_MODEL_LEN=8192
MAX_NUM_SEQS=32
MAX_NUM_BATCHED_TOKENS=32768
```

## Voir la VRAM utilisée

```bash
nvidia-smi
```

ou :

```bash
nvidia-smi --query-compute-apps=pid,process_name,used_memory \
  --format=csv
```

## systemd

Adapter `User`, `WorkingDirectory`, et `VENV_DIR`.

```bash
sudo cp systemd/api-reranker.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now api-reranker
sudo journalctl -u api-reranker -f
```

````

---

## `systemd/api-reranker.service`

```ini id="9mmbqd"
[Unit]
Description=vLLM API Reranker
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ailab
WorkingDirectory=/home/ailab/api-reranker
Environment=VENV_DIR=/home/ailab/venv/api-reranker
Environment=CUDA_VISIBLE_DEVICES=0
ExecStart=/bin/bash -lc './run.sh 0.0.0.0 8000'
Restart=always
RestartSec=5
TimeoutStartSec=600
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
````

---

## Commandes propres pour repartir

```bash id="a5rbw6"
cd ~/api-reranker

chmod +x install.sh run.sh

rm -rf "$HOME/venv/$(basename "$PWD")"

./install.sh

cp -n .env.example .env
nano .env

./run.sh
```

[1]: https://docs.vllm.ai/en/v0.19.1/examples/pooling/score/?utm_source=chatgpt.com "Score - vLLM"
[2]: https://docs.vllm.ai/en/stable/configuration/engine_args/?utm_source=chatgpt.com "Engine Arguments - vLLM"
