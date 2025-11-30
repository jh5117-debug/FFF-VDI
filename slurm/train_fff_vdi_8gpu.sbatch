#!/bin/bash
#SBATCH --job-name=fffvdi_train
#SBATCH --partition=pgpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:8
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=48:00:00
#SBATCH --output=logs/%x-%j.out
set -e
echo "[SLURM] Job ID: $SLURM_JOB_ID"
echo "[SLURM] Node: $(hostname)"
echo "[SLURM] GPUs requested: 8"
##############################
# Activate mamba environment
##############################
source ~/.bashrc
mamba activate fff-vdi
export HF_TOKEN="hf_xxxxxxxxxxxxxxxxx"
export HUGGINGFACE_HUB_TOKEN="$HF_TOKEN"
##############################
# DGX A100 Optimizations
##############################
export NCCL_TOPO_FILE=/opt/nccl_topo/dgx-a100-topo.xml
export NCCL_NET_GDR_LEVEL=3
export NCCL_IB_DISABLE=0
export NCCL_P2P_LEVEL=SYS
export CUDA_DEVICE_ORDER=PCI_BUS_ID
##############################
# Move to project directory
##############################
cd "$SLURM_SUBMIT_DIR"
echo "[SLURM] Working dir: $(pwd)"
##############################
# Start 8-GPU training
##############################
echo "[SLURM] Starting training on 8 GPUs..."
accelerate launch \
    --multi_gpu \
    --num_processes 8 \
    --mixed_precision fp16 \
    train.py
echo "[SLURM] Training finished."
