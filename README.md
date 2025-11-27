# FFF-VDI Training on HPC Cluster

<div align="center">

<h3>Video Diffusion Models are Strong Video Inpainter (FFF-VDI)</h3>

<a href="[https://arxiv.org/abs/2408.11402](https://arxiv.org/abs/2408.11402)">
  <img src="[https://img.shields.io/badge/ArXiv-2408.11402-red](https://img.shields.io/badge/ArXiv-2408.11402-red)" />
</a>

<br/><br/>

<div>
    <a href="[https://hydragon.co.kr](https://hydragon.co.kr)" target="_blank">Minhyeok Lee <sup>1</sup></a>&emsp;
    <a href="[https://suhwan-cho.github.io](https://suhwan-cho.github.io)" target="_blank">Suhwan Cho <sup>1</sup></a>&emsp;
    <a target="_blank">Chajin Shin <sup>1</sup></a>&emsp;
    <a href="[https://jho-yonsei.github.io](https://jho-yonsei.github.io)" target="_blank">Jungho Lee <sup>1</sup></a>&emsp;
    <a target="_blank">Sunghun Yang <sup>1</sup></a>&emsp;
    <a target="_blank">Sangyoun Lee <sup>1</sup></a>&emsp;
</div>

<br/>

<div>
  <sup>1</sup> 延世大学 (Yonsei University)
</div>

<br/>

<i><strong><a href="[https://aaai.org/conference/aaai/aaai-25/](https://aaai.org/conference/aaai/aaai-25/)" target="_blank">AAAI 2025</a></strong></i>
</div>

---

## 📌 项目说明 (Fork Note)
本项目针对 **Slurm HPC 集群** 进行了工程化适配。
遵循 HPC 最佳实践，我们将训练流程严格拆分为 **数据准备**、**环境构建** 和 **作业提交** 三个独立步骤，以分离 I/O 密集型任务与计算密集型任务。

---

## 📋 整体流程概览 (Workflow)

请严格按照以下顺序执行。前两步涉及大量网络下载和文件写入，**必须在登录节点 (Login Node) 运行**。

1.  **数据准备 (Login Node)**：运行下载脚本，获取并整理 YouTube-VOS 数据集。
2.  **环境安装 (Login Node)**：运行安装脚本，建立 `fff-vdi` Conda 环境。
3.  **提交训练 (Slurm)**：提交 `.sbatch` 作业，在计算节点使用 GPU 进行训练。

---

## 🚀 详细操作指南

### 第一步：数据准备 (Data Preparation)

我们提供了一个脚本，使用 Hugging Face 公共镜像自动下载并整理数据（无需 Token）。
**请在登录节点终端运行。**

#### 1. 运行下载脚本
```bash
# 语法：bash scripts/download_youtubevos_2019.sh <你的数据根目录>
# 注意：请确保您对该目录有写入权限

bash scripts/download_youtubevos_2019.sh /gpfs/data/YouTubeVOS
```

该脚本会自动执行：
* **下载**：从镜像源下载 `train.zip`。
* **解压**：自动解压并清理压缩包。
* **整理**：将目录重组为标准结构 (`youtube-vos/JPEGImages`)。

#### 2. 验证目录结构
脚本运行完成后，请检查目录结构是否如下所示：
```text
/gpfs/data/YouTubeVOS/          <-- 根目录
└── youtube-vos/
    └── JPEGImages/             <-- 关键目录
        ├── 00a23ccf53/         <-- 视频帧文件夹
        ├── 00ad5016a4/
        └── ...
```

---

### 第二步：环境安装 (Environment Setup)

**请在登录节点终端运行。**
这步操作会创建 Conda 环境并安装 PyTorch 及依赖。

```bash
bash scripts/setup_env.sh
```

* 脚本会创建名为 `fff-vdi` 的环境 (Python 3.10)。
* 自动安装 `requirements.txt` 和 CUDA 兼容的 PyTorch。
* **幂等设计**：如果环境已存在，脚本会自动跳过，避免重复安装。

---

### 第三步：修改配置 (Configuration)

在提交作业前，必须确保配置文件里的路径与第一步下载的路径一致。

#### 1. 修改 `config.yaml`
打开项目根目录下的 `config.yaml`，修改 `dataset` 部分：

```yaml
# config.yaml

# dataset
# 【重要】路径必须指向 JPEGImages 文件夹
data_root: "/gpfs/data/YouTubeVOS/youtube-vos/JPEGImages"  

width: 512
height: 256
num_frames: 25
```

#### 2. 修改 Slurm 脚本 (可选)
打开 `slurm/train_fff_vdi_8gpu.sbatch`，根据集群要求修改头部参数：

```bash
#SBATCH --partition=gpu      <-- 修改为集群的 GPU 分区名
#SBATCH --gres=gpu:8         <-- GPU 数量
#SBATCH --time=72:00:00      <-- 申请时长
```

---

### 第四步：提交训练 (Submit Job)

一切准备就绪，现在可以将任务提交给调度系统：

```bash
sbatch slurm/train_fff_vdi_8gpu.sbatch
```

* **作业ID**：提交成功后会返回 Job ID。
* **日志**：训练日志会实时输出到 `logs/` 目录下（例如 `logs/fffvdi_train-12345.out`）。

---

## ⚠️ 常见问题 (FAQ)

**Q1: 首次运行时报错 `401 Client Error: Unauthorized`？**
* **原因**：主干模型 `stable-video-diffusion-img2vid-xt-1-1` 是受限模型（Gated Model）。
* **解决**：
    1.  去 Hugging Face 官网申请该模型权限。
    2.  获取 Access Token。
    3.  在登录节点运行：
        ```bash
        conda activate fff-vdi
        pip install huggingface_hub
        huggingface-cli login
        ```
    4.  或者，在 Slurm 脚本中添加 `export HF_TOKEN="你的token"`。

**Q2: 为什么要在登录节点先跑脚本？**
* **原因**：计算节点通常没有外网访问权限，无法下载数据；且在昂贵的 GPU 节点上进行下载和编译安装是对计算资源的浪费。我们的脚本支持断点续传和自动检测，但在登录节点预先完成是最佳实践。

**Q3: 训练输出在哪里？**
* 默认保存在 `config.yaml` 指定的 `output_dir`（默认为 `./output`），包含 Checkpoints 和验证视频。
