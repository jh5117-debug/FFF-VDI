#!/bin/bash
#SBATCH --job-name=fffvdi_train        # 周哥可改
#SBATCH --partition=gpu               # 周哥可改
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8           # 8 个进程，对应 8 张 GPU
#SBATCH --gres=gpu:8                  # 申请 8 张 GPU
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=72:00:00
#SBATCH --output=logs/%x-%j.out       # 日志文件

set -e

######## 1. 加载 shell 环境 ########
source ~/.bashrc

######## 2. 如果环境不存在，则自动构建 ########
# （setup_env.sh 现在是可重复执行的，多次跑也没问题）
echo "[FFF-VDI] Checking conda env fff-vdi ..."
if ! conda env list | awk '{print $1}' | grep -qx "fff-vdi"; then
  echo "[FFF-VDI] Conda env fff-vdi not found, running scripts/setup_env.sh ..."
  bash scripts/setup_env.sh
else
  echo "[FFF-VDI] Conda env fff-vdi already exists."
fi

# 无论是否刚刚创建，都激活一次
conda activate fff-vdi

######## 3. 数据集检查 & 自动下载 ########
# 这里约定数据根目录，和 config.yaml 里的 data_root 对应
DATA_ROOT=/gpfs/data/YouTubeVOS
YTVOS_JPEGS=${DATA_ROOT}/youtube-vos/JPEGImages

if [ ! -d "${YTVOS_JPEGS}" ]; then
  echo "[FFF-VDI] YouTube-VOS not found at ${YTVOS_JPEGS}, start downloading..."
  bash scripts/download_youtubevos_2019.sh "${DATA_ROOT}"
else
  echo "[FFF-VDI] Found YouTube-VOS at ${YTVOS_JPEGS}, skip download."
fi

######## 4. 切到项目目录 ########
# 建议让周哥在仓库根目录下 sbatch，这样可以直接用 SLURM_SUBMIT_DIR
cd "${SLURM_SUBMIT_DIR}"

######## 5. (可选) accelerate config，只需首次手动跑一次 ########
# accelerate config

######## 6. 启动训练 ########
echo "[FFF-VDI] Start training with accelerate ..."
accelerate launch train.py
