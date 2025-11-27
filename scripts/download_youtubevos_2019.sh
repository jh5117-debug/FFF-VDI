#!/usr/bin/env bash
# 集群/服务器专用版：从你自己的 Hugging Face 数据集下载 YouTube-VOS 2019 train.tar
# 用法：bash scripts/download_youtubevos_2019.sh /gpfs/data/YouTubeVOS
# 运行前请先在本机执行一次： huggingface-cli login

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 DATA_ROOT"
  echo "Example: $0 /gpfs/data/YouTubeVOS"
  exit 1
fi

DATA_ROOT="$1"

# ================= 配置区域 =================
# ✅ 用你自己的仓库 + 文件名
REPO_ID="JiaHuang01/YouTube-VOS_2019"
FILENAME="train.tar"
# ===========================================

# 目标结构：DATA_ROOT/youtube-vos/JPEGImages
YTVOS_DIR="${DATA_ROOT}/youtube-vos"
TARGET_DIR="${YTVOS_DIR}/JPEGImages"

echo "[download_hf] Target Root: ${DATA_ROOT}"

# 1. 如果已经有数据就直接跳过
if [ -d "${TARGET_DIR}" ] && [ "$(ls -A "${TARGET_DIR}")" ]; then
  echo "[download_hf] Data already exists at ${TARGET_DIR}. Skipping."
  exit 0
fi

mkdir -p "${DATA_ROOT}"
cd "${DATA_ROOT}"

# 2. 安装 huggingface_cli（如果没有）
if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "[download_hf] Installing huggingface_hub..."
  pip install "huggingface_hub[cli]"
fi

# 3. 下载（你的仓库是 private，所以要提前 huggingface-cli login 过）
echo "[download_hf] Downloading ${FILENAME} from ${REPO_ID} ..."
huggingface-cli download \
  --repo-type dataset "${REPO_ID}" "${FILENAME}" \
  --local-dir . \
  --local-dir-use-symlinks False

# 4. 解压 train.tar
echo "[download_hf] Extracting ${FILENAME} ..."
tar -xf "${FILENAME}"

# 5. 整理目录结构
echo "[download_hf] Organizing directory structure ..."

mkdir -p "${YTVOS_DIR}"

# 情况1: train.tar 里面是 train/JPEGImages/...
if [ -d "train/JPEGImages" ]; then
  mv train/JPEGImages "${YTVOS_DIR}/"
  rm -rf train
# 情况2: train.tar 里面直接是 JPEGImages/...
elif [ -d "JPEGImages" ]; then
  mv JPEGImages "${YTVOS_DIR}/"
fi

# 删除压缩包
rm -f "${FILENAME}"

# 6. 最终验证
if [ -d "${TARGET_DIR}" ]; then
  echo "[download_hf] ✅ Success! Data is ready at: ${TARGET_DIR}"
else
  echo "[download_hf] ❌ Error: Directory organization failed."
  exit 1
fi
