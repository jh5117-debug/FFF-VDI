#!/usr/bin/env bash
# 修改版：从 Hugging Face 私有仓库下载 YouTube-VOS
# 用法：bash scripts/download_youtubevos_2019.sh /home/hj/data/ytvos

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 DATA_ROOT"
  exit 1
fi

DATA_ROOT="$1"

# ================= 配置区域 =================
# 你的 HF 仓库 ID (根据你的截图填写的)
REPO_ID="JiaHuang01/YouTube-VOS_2019"
# 你上传的文件名
FILENAME="train.tar"   
# ===========================================

echo "[download_hf] Target Dir: ${DATA_ROOT}"
echo "[download_hf] Repo: ${REPO_ID}"

mkdir -p "${DATA_ROOT}"
cd "${DATA_ROOT}"

# 1. 检查是否已有数据
if [ -d "JPEGImages" ] && [ "$(ls -A JPEGImages)" ]; then
    echo "[download_hf] JPEGImages already exists and is not empty. Skipping."
    exit 0
fi

# 2. 检查工具
if ! command -v huggingface-cli >/dev/null 2>&1; then
    echo "Installing huggingface_hub..."
    pip install "huggingface_hub[cli]"
fi

# 3. 下载
echo "[download_hf] Downloading ${FILENAME}..."
# 注意：你的仓库是 Private，运行脚本前必须先执行 huggingface-cli login
huggingface-cli download --repo-type dataset ${REPO_ID} ${FILENAME} --local-dir . --local-dir-use-symlinks False

# 4. 解压
echo "[download_hf] Extracting..."
if [[ "${FILENAME}" == *.zip ]]; then
    unzip -q -o ${FILENAME}
elif [[ "${FILENAME}" == *.tar ]]; then
    tar -xf ${FILENAME}
fi

# 5. 整理目录结构 (关键步骤)
# 我们需要确保最终路径是 /home/hj/data/ytvos/JPEGImages
echo "[download_hf] Organizing..."

# 如果解压出来是 train/JPEGImages
if [ -d "train/JPEGImages" ]; then
    mv train/JPEGImages ./
    rm -rf train
# 如果解压出来是 youtube-vos/JPEGImages
elif [ -d "youtube-vos/JPEGImages" ]; then
    mv youtube-vos/JPEGImages ./
    rm -rf youtube-vos
# 如果解压出来就是 JPEGImages (不做操作)
fi

echo "[download_hf] Done."
echo "Check contents sample:"
ls JPEGImages | head -n 5