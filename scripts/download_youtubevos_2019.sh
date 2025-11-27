#!/usr/bin/env bash
# 集群专用版：下载 YouTube-VOS 2019 (使用公共镜像，无需登录)
# 用法：bash scripts/download_youtubevos_2019.sh /gpfs/data/YouTubeVOS

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 DATA_ROOT"
  echo "Example: $0 /gpfs/data/YouTubeVOS"
  exit 1
fi

DATA_ROOT="$1"

# ================= 配置区域 =================
# 使用 Hugging Face 上的公共数据集镜像，包含 train.zip
REPO_ID="ecoz/YouTube-VOS-2019"
FILENAME="train.zip"
# ===========================================

# 目标结构：DATA_ROOT/youtube-vos/JPEGImages
YTVOS_DIR="${DATA_ROOT}/youtube-vos"
TARGET_DIR="${YTVOS_DIR}/JPEGImages"

echo "[download_hf] Target Root: ${DATA_ROOT}"

# 1. 检查是否存在
if [ -d "${TARGET_DIR}" ] && [ "$(ls -A ${TARGET_DIR})" ]; then
    echo "[download_hf] Data already exists at ${TARGET_DIR}. Skipping."
    exit 0
fi

mkdir -p "${DATA_ROOT}"
cd "${DATA_ROOT}"

# 2. 检查工具 (Admin 可能没装 hf cli)
if ! command -v huggingface-cli >/dev/null 2>&1; then
    echo "[download_hf] Installing huggingface_hub..."
    pip install "huggingface_hub[cli]"
fi

# 3. 下载 (使用公共源，不需要 login)
echo "[download_hf] Downloading ${FILENAME} from public mirror ${REPO_ID}..."
huggingface-cli download --repo-type dataset ${REPO_ID} ${FILENAME} --local-dir . --local-dir-use-symlinks False

# 4. 解压
echo "[download_hf] Extracting..."
unzip -q -o ${FILENAME}

# 5. 整理目录结构 (Cluster Standard)
# 无论解压出来是什么，最终都要变成 youtube-vos/JPEGImages
echo "[download_hf] Organizing directory structure..."

mkdir -p "${YTVOS_DIR}"

# 情况A: 解压出 train/JPEGImages (常见)
if [ -d "train/JPEGImages" ]; then
    mv train/JPEGImages "${YTVOS_DIR}/"
    rm -rf train
# 情况B: 解压出 JPEGImages (直接在根目录)
elif [ -d "JPEGImages" ]; then
    mv JPEGImages "${YTVOS_DIR}/"
fi

# 清理
rm -f ${FILENAME}

# 6. 验证
if [ -d "${TARGET_DIR}" ]; then
    echo "[download_hf] Success! Data is ready at: ${TARGET_DIR}"
else
    echo "[download_hf] Error: Directory organization failed."
    exit 1
fi