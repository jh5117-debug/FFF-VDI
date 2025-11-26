#!/bin/bash
#SBATCH --job-name=fffvdi_train
#SBATCH --partition=gpu           # 周哥改
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8       # 8 个进程，对应 8 张 GPU
#SBATCH --gres=gpu:8              # 申请 8 张 GPU
#SBATCH --cpus-per-task=8         # 每个进程的 CPU 数量，可按集群情况改
#SBATCH --mem=200G                # 内存大小也按集群情况调
#SBATCH --time=72:00:00           # 最大运行时间
#SBATCH --output=logs/%x-%j.out   # 日志文件

# ===== 1. 加载环境（周哥会改成自己习惯的写法）=====
source ~/.bashrc
conda activate fff-vdi

# ===== 2. 切到项目目录 =====
cd /path/to/FFF-VDI   # 周哥改

# 如果需要先配置 accelerate，只做一次就行
# accelerate config

# ===== 3. 启动训练 =====
accelerate launch train.py
