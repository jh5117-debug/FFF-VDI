#!/usr/bin/env bash
set -e

# 一键创建并安装训练环境（可重复执行）

ENV_NAME=fff-vdi
REQ_FLAG="$HOME/.fff_vdi_requirements_installed"

# 确保 conda 命令可用
source ~/.bashrc

# 1. 创建 conda 环境（如果不存在）
if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  echo "[FFF-VDI] Conda env ${ENV_NAME} already exists, skip conda create."
else
  echo "[FFF-VDI] Creating conda env ${ENV_NAME} (python=3.10)..."
  conda create -y -n ${ENV_NAME} python=3.10
fi

# 2. 激活环境
conda activate ${ENV_NAME}

# 3. 安装依赖（只安装一次）
if [ ! -f "${REQ_FLAG}" ]; then
  echo "[FFF-VDI] Installing PyTorch and Python requirements..."
  pip install torch torchvision
  pip install -r requirements.txt
  touch "${REQ_FLAG}"
  echo "[FFF-VDI] Requirements installed. Flag: ${REQ_FLAG}"
else
  echo "[FFF-VDI] Requirements already installed, skip pip install."
fi
