# api-reranker

Serveur vLLM CUDA 13 pour `BAAI/bge-reranker-v2-m3` ou un fork compatible, exposé via `/score`.

## Installation

```bash
chmod +x install.sh run.sh
./install.sh

cp .env.example .env
nano .env
````

Le venv Python 3.12 est créé automatiquement dans :

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

## Nom servi et alias optionnels du modèle

Les trois variables ont des rôles distincts :

- `MODEL_ID` indique le modèle à charger ;
- `SERVED_MODEL_NAME` change, de manière optionnelle, son nom principal dans l’API ;
- `MODEL_ALIAS` ajoute, de manière optionnelle, un second nom accepté par l’API.

Tu peux donc définir le nom servi et son alias dans `.env` :

```dotenv
MODEL_ID=BAAI/bge-reranker-v2-m3
SERVED_MODEL_NAME=bge-reranker-v2-m3
MODEL_ALIAS=reranker
```

Le modèle chargé reste celui indiqué par `MODEL_ID`. Les requêtes peuvent utiliser le
nom principal ou l’alias :

```json
{
  "model": "reranker"
}
```

Si seul `MODEL_ALIAS` est défini, `MODEL_ID` reste le nom principal et l’alias est
ajouté. Si les deux options sont absentes ou vides, vLLM utilise directement
`MODEL_ID`.

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

## Python, dépendances Transformers et cache Hugging Face

`install.sh` crée le venv avec Python 3.12 par défaut :

```bash
uv venv "$VENV_DIR" --python 3.12
```

Pour éviter l’erreur `huggingface-hub>=0.34.0,<1.0 is required ... but found huggingface-hub==1.26.0`, le script installe `huggingface-hub[cli]>=0.34.0,<1.0`, compatible avec `transformers`.

`run.sh` ne force plus de cache Hugging Face local au projet. Sans variable `HF_HOME` ou `HUGGINGFACE_HUB_CACHE`, Hugging Face utilise son répertoire par défaut :

```bash
~/.cache/huggingface
```

Tu peux toujours surcharger ce chemin dans `.env` si nécessaire.

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
