<div align="center">

<h3>Video Diffusion Models are Strong Video Inpainter (FFF-VDI)</h3>

<br/>

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
  <sup>1</sup> Yonsei University
</div>

<br/>

<i><strong><a href="[https://aaai.org/conference/aaai/aaai-25/](https://aaai.org/conference/aaai/aaai-25/)" target="_blank">AAAI 2025</a></strong></i>

<br/><br/>

</div>

> **Note (fork status)** > This repository is an *unofficial fork* of
> [Hydragon516/FFF-VDI](https://github.com/Hydragon516/FFF-VDI),
> mainly used for reproduction on an HPC cluster.  
> The core model and training code are from the original authors; this fork only adds:
> - a `requirements.txt` for easier environment setup,
> - helper scripts under `scripts/` (environment & training),
> - a Slurm template under `slurm/` for multi-GPU training.

---

## 1. Overview

FFF-VDI proposes **First Frame Filling Video Diffusion Inpainting** built on
a pre-trained image-to-video diffusion model.  
Instead of relying on optical flow for propagation, FFF-VDI injects noise
latents from future frames into the masked region of the first frame,
then fine-tunes an img2vid diffusion backbone to generate an inpainted video.
This design reduces sensitivity to flow errors and yields more natural and
temporally consistent videos, especially for large missing regions.

<p align="center">
  <img width="100%" alt="teaser" src="./assets/bmx-trees.gif">
</p>

---

## 2. Environment Setup

You can either follow the original manual steps or use the helper script in this fork.

### 2.1 Clone this fork

```bash
git clone https://github.com/jh5117-debug/FFF-VDI.git
cd FFF-VDI
```

### 2.2 One-click setup with `scripts/setup_env.sh`

This repository provides a simple environment script:

```bash
bash scripts/setup_env.sh
```

The script will:

1. Create a Conda environment `fff-vdi` with Python 3.10
2. Activate it
3. Install PyTorch / torchvision (CPU/GPU build depends on your local `pip` index)
4. Install the remaining dependencies from `requirements.txt`

> On HPC, you may want to **comment out** the `conda create` line and instead
> load your own Anaconda/Miniconda module, or adjust the PyTorch version to
> match the cluster CUDA.

If you prefer manual installation, the equivalent steps are:

```bash
conda create -n fff-vdi python=3.10
conda activate fff-vdi

pip install torch torchvision            # choose a CUDA build suitable for the cluster
pip install -r requirements.txt
```

### 2.3 Configure `accelerate`

FFF-VDI uses [🤗 Accelerate](https://github.com/huggingface/accelerate) to
launch distributed training:

```bash
accelerate config
```

Configure number of GPUs, mixed precision, etc. according to your machine / cluster.

---

## 3. Dataset

Training uses the **YouTube-VOS** train split.
Because FFF-VDI **randomly generates masks on the fly**, only RGB frames are required.

Expected directory layout:

```text
DATASET_ROOT/
  youtube-vos/
    JPEGImages/
      00a23ccf53/
      00ad5016a4/
      ...
```

In this fork, the default path in `config.yaml` is a **placeholder**:

```yaml
# dataset
data_root: "/data/fff_vdi/youtube-vos/JPEGImages"  # TODO: replace with your real path
width: 512
height: 256
num_frames: 25
```

On your own machine / on the HPC cluster, **change `data_root`** to the actual
location of `JPEGImages`.
No extra mask dataset is needed.

---

## 4. Training

### 4.1 Simple training command (no Slurm)

Once the dataset path is correct and the environment is ready:

```bash
# from the project root
conda activate fff-vdi
accelerate launch train.py
```

By default, training hyper-parameters (batch size, learning rate, number of
training steps, mixed precision, etc.) are controlled by `config.yaml`:

```yaml
# training parameters
seed: 123
per_gpu_batch_size: 1
learning_rate: 0.00001   # = 1e-5
max_train_steps: 100000
validation_steps: 1000
mixed_precision: "fp16"
checkpoints_total_limit: 1
output_dir: "./output"
```

You can also use the helper shell script in this fork:

```bash
bash scripts/train_fff_vdi.sh
```

`train_fff_vdi.sh` does:

1. `source ~/.bashrc`
2. `conda activate fff-vdi`
3. `cd /path/to/FFF-VDI`    ← modify this line if needed
4. `accelerate launch train.py`

---

## 5. Multi-GPU Training with Slurm (HPC)

For HPC environments with Slurm, this fork includes a template:
`slurm/train_fff_vdi_8gpu.sbatch`.

Key parts:

```bash
#!/bin/bash
#SBATCH --job-name=fffvdi_train
#SBATCH --partition=gpu           # TODO: set cluster partition
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8       # one task per GPU
#SBATCH --gres=gpu:8              # request 8 GPUs
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G
#SBATCH --time=72:00:00
#SBATCH --output=logs/%x-%j.out

# 1. Load environment
source ~/.bashrc
conda activate fff-vdi

# 2. Go to project directory
cd /path/to/FFF-VDI        # TODO: change to actual path on the cluster

# (Optional) run once before training to configure accelerate
# accelerate config

# 3. Launch training
accelerate launch train.py
```

**What the HPC user needs to modify:**

1. `#SBATCH --partition`, `--account` (if required), `--cpus-per-task`, `--mem`, `--time`
2. The `cd /path/to/FFF-VDI` line – set to the actual path where the repo is cloned
3. If using a different Conda env name, change `conda activate fff-vdi`
4. Ensure `config.yaml` has the correct `data_root` path on the cluster filesystem

Then start training via:

```bash
sbatch slurm/train_fff_vdi_8gpu.sbatch
```

We strongly recommend an environment with **8×A100/H100 (80GB)** or similar VRAM
for full training runs.

---

## 6. Inference

This fork currently focuses on **training setup and reproduction**.
For inference on trained checkpoints (long-video inpainting, etc.), please
refer to the original repository and paper. Once the upstream repo releases
official inference scripts for FFF-VDI, they can be integrated here.

---

## 7. TODO

* [x] Add training & environment details for reproduction
* [ ] Add DNA module support (when officially available)
* [ ] Add long-video inference code (when officially available)

---

## 8. Acknowledgements

* Official repository: [Hydragon516/FFF-VDI](https://github.com/Hydragon516/FFF-VDI)
* This fork only adds environment, data and Slurm helper scripts to make
  large-scale training easier on HPC clusters (e.g., 8×A100 / 8×H100).

If you use this work in your research, please cite the original FFF-VDI paper
as described in the upstream repository.
