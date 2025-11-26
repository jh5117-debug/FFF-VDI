<div align="center">

<h3>Video Diffusion Models are Strong Video Inpainter (FFF-VDI)</h3>

<a href="https://arxiv.org/abs/2408.11402">
  <img src="https://img.shields.io/badge/ArXiv-2408.11402-red" />
</a>

<br/><br/>

<div>
    <a href="https://hydragon.co.kr" target="_blank">Minhyeok Lee <sup>1</sup></a>&emsp;
    <a href="https://suhwan-cho.github.io" target="_blank">Suhwan Cho <sup>1</sup></a>&emsp;
    <a target="_blank">Chajin Shin <sup>1</sup></a>&emsp;
    <a href="https://jho-yonsei.github.io" target="_blank">Jungho Lee <sup>1</sup></a>&emsp;
    <a target="_blank">Sunghun Yang <sup>1</sup></a>&emsp;
    <a target="_blank">Sangyoun Lee <sup>1</sup></a>&emsp;
</div>

<br/>

<div>
  <sup>1</sup> 延世大学 (Yonsei University)
</div>

<br/>

<i><strong><a href="https://aaai.org/conference/aaai/aaai-25/" target="_blank">AAAI 2025</a></strong></i>

<br/><br/>
</div>

> **Fork 说明**
>
> 本项目是 [Hydragon516/FFF-VDI](https://github.com/Hydragon516/FFF-VDI) 的 **非官方 Fork 版本**，专门针对 **H100 GPU 集群** 训练进行了适配。
> 核心模型和训练逻辑遵循原始实现；此 Fork 主要增加了锁定的依赖版本以及针对高性能计算（HPC）环境的简要说明。

---

## 1. 先决条件 (Prerequisites)

要在 H100 集群上训练 FFF-VDI，您需要：

- 至少一个多 GPU 节点（例如：8张 H100 80GB 显卡），并安装了较新的 NVIDIA 驱动。
- `git` 和 **Conda** (Anaconda / Miniconda)。
- 一个 [Hugging Face](https://huggingface.co/) 账号，且拥有访问 `stabilityai/stable-video-diffusion-img2vid-xt-1-1` 的权限。
- 训练节点需具备 **出站互联网访问权限**（用于首次下载预训练的主干网络）。

---

## 2. 代码库与环境配置

以下所有命令均应在调度程序分配的 **GPU 节点内部** 运行（例如在 Slurm job 中）。

```bash
# 克隆此 fork 仓库
git clone [https://github.com/jh5117-debug/FFF-VDI.git](https://github.com/jh5117-debug/FFF-VDI.git)
cd FFF-VDI/FFF-VDI

# 创建并激活 Conda 环境
conda create -n fff-vdi python=3.10
conda activate fff-vdi

# 安装所有依赖项 (torch, diffusers, transformers 等)
pip install -r requirements.txt
```

> **注意：** `requirements.txt` 是从一个可正常工作的训练环境中生成的，包含固定版本的 PyTorch, Diffusers, Transformers 等。在某些集群上，您可能需要调整 torch / CUDA 版本以匹配本地策略。

---

## 3. 获取 Stable Video Diffusion 权限 (Hugging Face)

FFF-VDI 使用受门控限制（Gated）的 Stable Video Diffusion 模型作为 img2vid 主干：
`stabilityai/stable-video-diffusion-img2vid-xt-1-1`。

### 3.1 在浏览器中操作

1. 打开 [https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt-1-1](https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt-1-1)。
2. 登录您的 Hugging Face 账号。
3. 滚动到许可/条款部分，同意条款，填写简短表单（例如用途填写：“Academic non-commercial research / video inpainting”），然后提交。
4. 前往 **Settings (设置)** → **Access Tokens (访问令牌)**，创建一个具有 **Read (读取)** 权限的新令牌（建议命名为 `fff-vdi-h100`）。
5. 复制该令牌字符串。

### 3.2 在集群上操作

在 H100 节点上，确保护境已激活并登录：

```bash
conda activate fff-vdi

# 如果尚未安装 CLI 工具
pip install "huggingface_hub[cli]"

# 登录 (在此处粘贴您的令牌)
huggingface-cli login
```

若看到 `Login successful` 即表示成功。令牌将存储在您的主目录下，Diffusers / Transformers 库会自动调用它。

---

## 4. 数据集准备 (YouTube-VOS)

FFF-VDI 使用 YouTube-VOS 训练集。只需 RGB 帧；掩码（Masks）会在训练时动态生成。

### 预期目录结构

```text
DATA_ROOT/
  youtube-vos/
    JPEGImages/
      00a23ccf53/
        00000.jpg
        00001.jpg
        ...
      00ad5016a4/
        00000.jpg
        00001.jpg
        ...
      ...
```

- `JPEGImages/` 下的每个子文件夹对应一个视频。
- 帧文件按顺序命名为 5 位数字的 `.jpg` 文件。

### 修改配置

在此 Fork 中，数据集路径在 `config.yaml` 中配置：

```yaml
# config.yaml

# dataset
data_root: "/data/fff_vdi/youtube-vos/JPEGImages"   # <<< 修改此处
width: 512
height: 256
num_frames: 25
```

请将 `data_root` 更改为集群上 `JPEGImages` 的绝对路径，例如：

```yaml
data_root: "/gpfs/data/YouTubeVOS/youtube-vos/JPEGImages"
```

其他训练超参数（Batch size, 学习率, 步数等）也在 `config.yaml` 中定义，可根据需要进行微调。

---

## 5. 配置 Accelerate

在 `fff-vdi` 环境中运行一次配置向导：

```bash
conda activate fff-vdi
accelerate config
```

**针对 8x H100 节点的建议选项：**

- **Compute environment:** This machine
- **Distributed mode:** MULTI GPU
- **Number of processes:** 8
- **Number of machines:** 1
- **Mixed precision:** fp16

这将在 `~/.cache/huggingface/accelerate/default_config.yaml` 生成配置文件，`accelerate launch` 将复用此配置。

---

## 6. 训练命令 (H100 节点)

完成上述步骤后，即可启动训练：

```bash
conda activate fff-vdi
cd /path/to/FFF-VDI/FFF-VDI

accelerate launch train.py
```

如果您希望显式覆盖 GPU 数量或精度设置，可以使用命令行参数：

```bash
accelerate launch \
  --num_processes 8 \
  --mixed_precision fp16 \
  train.py
```

`accelerate` 将根据配置文件加上命令行标志，在节点上的每个 GPU 启动一个训练进程。

### Slurm 作业脚本示例

在 Slurm 作业脚本中，训练部分通常如下所示：

```bash
#SBATCH --gres=gpu:8
#SBATCH --ntasks-per-node=8
# ... 其他 Slurm 选项 ...

source ~/.bashrc
conda activate fff-vdi
cd /path/to/FFF-VDI/FFF-VDI

accelerate launch train.py
```

日志和检查点（Checkpoints）将根据 `config.yaml` 中的设置写入（默认为 `output_dir: "./output"`）。
