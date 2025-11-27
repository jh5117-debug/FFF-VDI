#!/bin/bash
#SBATCH --job-name=fffvdi_train
#SBATCH --partition=gpu           # 管理员根据集群实际情况修改
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8       # 8进程
#SBATCH --gres=gpu:8              # 8张卡
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=72:00:00
#SBATCH --output=logs/%x-%j.out

set -e

# =========================================================
# 1. 环境初始化
# =========================================================
source ~/.bashrc

echo "[SLURM] Job ID: $SLURM_JOB_ID"
echo "[SLURM] Node: $(hostname)"

# 检查并自动创建环境
echo "[SLURM] Checking conda environment..."
if ! conda env list | awk '{print $1}' | grep -qx "fff-vdi"; then
  echo "[SLURM] Environment 'fff-vdi' not found. Creating it now..."
  bash scripts/setup_env.sh
else
  echo "[SLURM] Environment 'fff-vdi' found."
fi

conda activate fff-vdi

# =========================================================
# 2. 数据准备 (自动下载)
# =========================================================
# 定义数据存放的根目录 (与 config.yaml 对应)
# 脚本会自动下载到 /gpfs/data/YouTubeVOS/youtube-vos/JPEGImages
DATA_ROOT_BASE="/gpfs/data/YouTubeVOS"
TARGET_PATH="${DATA_ROOT_BASE}/youtube-vos/JPEGImages"

echo "[SLURM] Checking dataset at ${TARGET_PATH}..."
if [ ! -d "${TARGET_PATH}" ]; then
  echo "[SLURM] Dataset not found. Launching download script..."
  bash scripts/download_youtubevos_2019.sh "${DATA_ROOT_BASE}"
else
  echo "[SLURM] Dataset found. Skipping download."
fi

# =========================================================
# 3. 启动训练
# =========================================================
# 确保在提交目录 (项目根目录)
cd "${SLURM_SUBMIT_DIR}"

echo "[SLURM] Starting training..."
# accelerate config 通常不需要在脚本里跑，默认配置或命令行参数即可
# 这里直接启动，accelerate 会自动检测 8 卡环境
accelerate launch --multi_gpu --num_processes=8 train.py

echo "[SLURM] Training finished."