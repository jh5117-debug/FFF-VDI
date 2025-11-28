#!/bin/bash
#SBATCH --job-name=fffvdi_train
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --gres=gpu:8
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=72:00:00
#SBATCH --output=logs/%x-%j.out

set -e

echo "[SLURM] Job ID: $SLURM_JOB_ID"
echo "[SLURM] Node: $(hostname)"

# 1. 激活已经提前安装好的环境（不再创建/装包）
source ~/.bashrc
conda activate fff-vdi

# 2. 切换到提交目录（项目根目录）
cd "${SLURM_SUBMIT_DIR}"
echo "[SLURM] Working dir: $(pwd)"

# 3. 启动多卡训练（参数全部写在这里）
echo "[SLURM] Starting training..."
accelerate launch \
  --multi_gpu \
  --num_machines=1 \
  --num_processes=8 \
  --mixed_precision=fp16 \
  train.py

echo "[SLURM] Training finished."
