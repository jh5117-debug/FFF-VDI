#!/bin/bash
# 本地单机训练启动脚本

# 1. 激活环境
source ~/.bashrc
# 如果 source 不生效，请检查你的 conda 安装路径，或者直接在终端先 activate 好
# conda activate fff-vdi

# 2. 设置数据根目录
DATA_ROOT="/home/hj/data/ytvos"

# 3. 自动检查/下载数据 (调用上面改好的下载脚本)
if [ ! -d "${DATA_ROOT}/JPEGImages" ]; then
    echo "[Run] Data not found. Starting download from Hugging Face..."
    # 确保脚本有执行权限
    chmod +x scripts/download_youtubevos_2019.sh
    bash scripts/download_youtubevos_2019.sh "${DATA_ROOT}"
else
    echo "[Run] Data found at ${DATA_ROOT}/JPEGImages"
fi

# 4. 启动训练
# 指定使用空闲的 3 号显卡 (根据你之前的 nvidia-smi 结果)
export CUDA_VISIBLE_DEVICES=3 

echo "[Run] Starting training on GPU ${CUDA_VISIBLE_DEVICES}..."
# accelerate launch 会读取 config.yaml
accelerate launch train.py