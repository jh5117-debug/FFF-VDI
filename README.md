# FFF-VDI Training on HPC Cluster

本仓库包含 FFF-VDI 模型的训练代码，已针对 HPC 集群环境（Slurm + Conda）进行了自动化封装。
管理员/用户仅需少量配置即可实现一键环境构建、数据下载与训练启动。

---

## 🚀 快速开始 (Quick Start)

### 1. 克隆代码
```bash
git clone https://github.com/jh5117-debug/FFF-VDI.git
cd FFF-VDI
```

### 2. 修改配置 (关键步骤)
在提交作业前，请务必根据集群实际情况修改以下两个文件中的路径和资源设置。

#### A. 修改 Slurm 脚本 (`slurm/train_fff_vdi_8gpu.sbatch`)
打开文件，关注顶部的 `#SBATCH` 设置和中间的 `DATA_ROOT_BASE` 变量。

```bash
# --- 资源设置 ---
#SBATCH --partition=gpu          <-- [必改] 修改为您集群的 GPU 分区名
#SBATCH --gres=gpu:8             <-- [可选] 修改 GPU 数量
# ...

# --- 数据路径设置 ---
# 脚本会自动在此目录下创建 youtube-vos/JPEGImages 并下载数据
# 如果您没有 /gpfs/data 的写入权限，请改为您的个人目录 (e.g., /scratch/user/data)
DATA_ROOT_BASE="/gpfs/data/YouTubeVOS"   <-- [必改] 修改为您希望存放数据的目录
```

> **注意**：脚本会自动运行 `mkdir -p` 创建该目录，不需要手动新建文件夹。

#### B. 同步修改配置文件 (`config.yaml`)
确保 `config.yaml` 里的 `data_root` 与上面的路径保持一致。

```yaml
# dataset
# 请确保这里的路径 = $DATA_ROOT_BASE/youtube-vos/JPEGImages
data_root: "/gpfs/data/YouTubeVOS/youtube-vos/JPEGImages"  <-- [必改] 需与 Slurm 脚本一致
```

### 3. 一键启动
配置修改完成后，直接提交作业：

```bash
sbatch slurm/train_fff_vdi_8gpu.sbatch
```

---

## 🛠️ 脚本自动化流程说明

运行 `sbatch` 后，脚本将按顺序自动执行以下操作：

1.  **环境检查**：
    * 检查是否存在名为 `fff-vdi` 的 Conda 环境。
    * **如果不存在**：自动调用 `scripts/setup_env.sh` 创建环境并安装 PyTorch 及依赖。
    * **如果存在**：自动激活环境。

2.  **数据准备**：
    * 检查 `data_root` 下是否已有数据。
    * **如果不存在**：自动调用 `scripts/download_youtubevos_2019.sh`。
    * 该脚本会使用 Hugging Face 公共镜像（无需 Token）下载 YouTube-VOS 2019 数据集 (`train.zip`)，解压并自动整理目录结构。

3.  **开始训练**：
    * 自动调用 `accelerate launch` 启动分布式训练。
    * 日志将输出到 `logs/` 目录下。

---

## 📂 目录结构示例

脚本执行完毕后，您的数据目录结构将如下所示：

```text
YOUR_DATA_ROOT/             (例如 /gpfs/data/YouTubeVOS)
└── youtube-vos/
    └── JPEGImages/
        ├── 00a23ccf53/     (视频帧文件夹)
        ├── 00ad5016a4/
        └── ...
```

---

## 📋 常见问题

**Q1: 下载数据太慢或失败？**
* 脚本默认使用 Hugging Face 镜像。如果集群网络受限，请手动下载 `train.zip` 并解压到 `JPEGImages` 目录。

**Q2: 提示 `mkdir: cannot create directory`: Permission denied?**
* 这说明您设置的 `DATA_ROOT_BASE` (如 `/gpfs/...`) 您没有写入权限。
* 请修改 `.sbatch` 和 `config.yaml`，将路径指向您的用户目录（如 `/home/username/data` 或 `/scratch/username/data`）。
