#!/bin/bash
set -e
source ~/.bashrc
conda activate fff-vdi

# 2. 进入项目目录（HPC 自己的路径）
cd /path/to/FFF-VDI  

# 3. 训练命令：官方推荐就是 accelerate launch train.py
# 周哥accelerate 的具体多卡配置,您现在 HPC 上先跑一次 `accelerate config`
accelerate launch train.py
