#!/usr/bin/env bash
# 下载并解压 YouTube-VOS 2019 训练集（内部镜像）
# 用法：bash scripts/download_youtubevos_2019.sh /gpfs/data/YouTubeVOS
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 DATA_ROOT"
  echo "Example: $0 /gpfs/data/YouTubeVOS"
  exit 1
fi

DATA_ROOT="$1"
YTVOS_ROOT="${DATA_ROOT}/youtube-vos"
JPEGS_DIR="${YTVOS_ROOT}/JPEGImages"

echo "[download_youtubevos_2019] DATA_ROOT = ${DATA_ROOT}"

# 已经有 JPEGImages 就直接退出
if [ -d "${JPEGS_DIR}" ]; then
  echo "[download_youtubevos_2019] Found ${JPEGS_DIR}, skip download."
  exit 0
fi

mkdir -p "${DATA_ROOT}"
cd "${DATA_ROOT}"

# ==== 1. 确保有 gdown 工具 ====
if ! command -v gdown >/dev/null 2>&1; then
  echo "[download_youtubevos_2019] gdown not found, installing via pip..."
  pip install gdown
fi

# ==== 2. 从 Google Drive 下载 train.tar ====
FILE_ID="1lU9jCX-H0ntwh87tt2cA0xEPeWOJzD6S"
echo "[download_youtubevos_2019] Downloading train.tar from Google Drive (id=${FILE_ID}) ..."
gdown --id "${FILE_ID}" -O train.tar

# ==== 3. 解压 train.tar ====
echo "[download_youtubevos_2019] Extracting train.tar ..."
tar xf train.tar

# ==== 4. 归一化目录结构到 youtube-vos/JPEGImages ====
if [ -d "JPEGImages" ]; then
  mkdir -p "${YTVOS_ROOT}"
  mv JPEGImages "${YTVOS_ROOT}/"
elif [ -d "train/JPEGImages" ]; then
  mkdir -p "${YTVOS_ROOT}"
  mv train/JPEGImages "${YTVOS_ROOT}/"
else
  echo "[download_youtubevos_2019] WARNING: cannot find JPEGImages directory after extract."
  echo "Please check ${DATA_ROOT} manually."
fi

echo "[download_youtubevos_2019] Done. Final path should be: ${JPEGS_DIR}"
