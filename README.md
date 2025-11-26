<div align="center">

<h3>Video Diffusion Models are Strong Video Inpainter (FFF-VDI)</h3>

<br/>

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
  <sup>1</sup> Yonsei University
</div>

<br/>

<i><strong><a href="https://aaai.org/conference/aaai/aaai-25/" target="_blank">AAAI 2025</a></strong></i>

<br/><br/>

</div>

> **Note (fork status)**  
> This repository is an *unofficial fork* of
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
