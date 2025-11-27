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