#!/usr/bin/env bash
set -e

# 一键创建并安装训练环境（可重复执行）

ENV_NAME=fff-vdi
REQ_FLAG="$HOME/.fff_vdi_requirements_installed"

# 确保 conda 命令可用
source ~/.bashrc

# 1. 创建 conda 环境（如果不存在）
if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  echo "[Setup] Conda env ${ENV_NAME} already exists."
else
  echo "[Setup] Creating conda env ${ENV_NAME} (python=3.10)..."
  conda create -y -n ${ENV_NAME} python=3.10
fi

# 2. 激活环境
# 注意：在脚本子进程中激活需要 source activate 或 conda activate
# 这里假设 conda init 已经配置好
eval "$(conda shell.bash hook)"
conda activate ${ENV_NAME}

# 3. 安装依赖（只安装一次）
if [ ! -f "${REQ_FLAG}" ]; then
  echo "[Setup] Installing PyTorch and requirements..."
  # 安装适合 CUDA 11.8/12.x 的 PyTorch (这里用默认稳定版)
  pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
  pip install -r requirements.txt
  
  # 标记已安装
  touch "${REQ_FLAG}"
  echo "[Setup] Dependencies installed."
else
  echo "[Setup] Dependencies already installed (Flag found)."
fi

########################################
# 4. 准备权重目录
########################################
WEIGHTS_DIR="$(pwd)/weights"
if [ ! -d "${WEIGHTS_DIR}" ]; then
  echo "[Setup] Creating weights directory at ${WEIGHTS_DIR}..."
  mkdir -p "${WEIGHTS_DIR}"
fi

########################################
# 5. 下载 RAFT 权重（如有必要）
########################################
RAFT_WEIGHTS="${WEIGHTS_DIR}/raft-things.pth"

if [ ! -f "${RAFT_WEIGHTS}" ]; then
  echo "[Setup] Downloading RAFT weights to ${RAFT_WEIGHTS}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L "https://huggingface.co/Iceclear/MGLD-VSR/resolve/main/raft-things.pth" \
      -o "${RAFT_WEIGHTS}"
    echo "[Setup] RAFT weights downloaded."
  else
    echo "[Setup][WARNING] 'curl' not found. Please manually download:"
    echo "  https://huggingface.co/Iceclear/MGLD-VSR/resolve/main/raft-things.pth"
    echo "and place it at: ${RAFT_WEIGHTS}"
  fi
else
  echo "[Setup] RAFT weights already exist: ${RAFT_WEIGHTS}"
fi

########################################
# 6. 下载 Flow Completion 权重（如有必要）
########################################
FLOWCOMP_WEIGHTS="${WEIGHTS_DIR}/recurrent_flow_completion.pth"

if [ ! -f "${FLOWCOMP_WEIGHTS}" ]; then
  echo "[Setup] Downloading Flow Completion weights to ${FLOWCOMP_WEIGHTS}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L "https://github.com/sczhou/ProPainter/releases/download/v0.1.0/recurrent_flow_completion.pth" \
      -o "${FLOWCOMP_WEIGHTS}"
    echo "[Setup] Flow Completion weights downloaded."
  else
    echo "[Setup][WARNING] 'curl' not found. Please manually download:"
    echo "  https://github.com/sczhou/ProPainter/releases/download/v0.1.0/recurrent_flow_completion.pth"
    echo "and place it at: ${FLOWCOMP_WEIGHTS}"
  fi
else
  echo "[Setup] Flow Completion weights already exist: ${FLOWCOMP_WEIGHTS}"
fi
