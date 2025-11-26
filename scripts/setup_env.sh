#!/bin/bash
# 一键创建并安装训练环境

conda create -y -n fff-vdi python=3.10
source ~/.bashrc
conda activate fff-vdi

# 按 README 装依赖
pip install torch torchvision
pip install -r requirements.txt
