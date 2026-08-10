# RP-4.1.3: Universal GPU/NPU acceleration

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.3` |
| **DESIGN.md** | Section 4 Targets — Universal GPU/NPU Acceleration |
| **Status** | `draft` |
| **PM.md row** | `4.1.3` (**not-started**) |
| **Product mapping** | No product GPU/NPU path. This is a design goal. |

## 1. Why this is in DESIGN.md

DESIGN.md Section 4:

> **Universal GPU/NPU Acceleration:** Native compilation to NVIDIA (PTX), AMD (ROCm), Intel (SPIR-V), and Apple Silicon (Metal). This gives zero-overhead tensor math and parallel compute. This bypasses Python and C++ bindings.

openOODA is a systems language. It must not force AI and HPC workloads through a foreign language interface. The design goal is first-class heterogeneous compute. This means the use of the same language, capability model, and contracts, compiled to vendor architectures.

This paper examines the multi-vendor landscape. It defines what "universal" means in practical terms.

## 2. Problem statement

### 2.1 Why systems languages use GPUs

- They run training and inference kernels, simulation algorithms, cryptography programs, and media codecs.
- **Binding problems:** Python-to-CUDA or C++-to-HIP wrappers break the OODA loop. They break the tooling, types, and capabilities.
- **Security:** GPU drivers and kernels are a large trusted computing base. Language-level capabilities must include device memory.

### 2.2 Why "universal" is difficult

Vendors do not share one portable architecture:

| Vendor | Programming model | Intermediate representation |
|---------------|-------------------|--------------|
| NVIDIA | CUDA | PTX to SASS |
| AMD | ROCm / HIP | LLVM-based GPU code |
| Intel | oneAPI / SYCL / OpenCL | SPIR-V or vendor code |
| Apple | Metal | MSL / AIR |
| Cross-vendor | SYCL, OpenCL, Vulkan, Kokkos, alpaka | Various |

openOODA cannot hit all four design targets with one compiler pass. It must use multiple backends or a portability layer. Portability layers like SYCL or MLIR have incomplete coverage and performance problems.

## 3. Related work

### 3.1 CUDA

NVIDIA CUDA is the standard industrial GPU platform. It has kernels similar to C and C++, rich libraries (such as cuBLAS and cuDNN), and mature tooling. Its restriction is that it only supports NVIDIA hardware. Languages usually bind to the CUDA runtime instead of building the stack again.

### 3.2 ROCm and HIP

AMD ROCm and HIP give a CUDA-like programming model for AMD GPUs. Migration guides focus on API similarity. Real code ports find differences in the architecture and library support.

### 3.3 SYCL and oneAPI

**SYCL** is a Khronos single-source C++ model for different devices. Implementations include Intel DPC++/oneAPI and AdaptiveCpp. They have paths to NVIDIA, AMD, and Intel. SYCL is the primary standard to "write once, run on many GPUs." But performance and features change in each implementation.

### 3.4 Metal

Apple Silicon compute uses **Metal** shaders and compute pipelines. It does not use CUDA. A universal claim that includes Apple must use Metal as a primary backend.

### 3.5 MLIR GPU dialect and AI compilers

The MLIR **`gpu` dialect** gives middle-level abstractions to launch kernels. These are similar to CUDA and OpenCL models. Modern AI compilers (like XLA, IREE, and Torch-MLIR) use a multi-level intermediate representation. They do not write PTX manually for every operation.

For openOODA, MLIR is a good research path. It goes from a language dialect to `gpu`, `linalg`, or `vector` to the vendor code (NVVM, ROCDL, or SPIR-V).

### 3.6 Language case studies

- **Julia:** The GPU ecosystem has multiple packages (CUDA.jl, AMDGPU.jl, oneAPI.jl). It does not have one universal backend.
- **Rust:** It uses `rust-gpu`, CUDA crates, and multiple stacks.
- **Mojo:** It uses MLIR pipelines strongly.

Lesson: Good systems languages ship multiple GPU backends with a shared host API.

## 4. Design rationale for openOODA

### 4.1 Capabilities on device memory

Extend the capability model (Section 3.1, Section 3.3):

- Use `&GpuCap` and device-queue tokens to launch kernels.
- Set memory quotas for host and device allocations.
- Do not permit silent unified-memory allocations without a capability token.

### 4.2 std::core vs accelerator surface

The `std::core` library stays pure and only for the host CPU. Accelerator operations are in explicit modules that need capability tokens. A user cannot import a tensor and get CUDA without a token.

### 4.3 Lowering strategy (recommended long-term)

```text
.oo parallel and tensor ops
    -> openOODA GPU IR
    -> MLIR dialects (optional stage)
    -> vendor backend (PTX, ROCm, SPIR-V, or Metal)
```

Short-term plan: Build one vendor backend first (likely CUDA, Vulkan, or SPIR-V). Do not build all four at the same time.

### 4.4 Relation to CPU backends

GPU acceleration does not replace Backend-C or LLVM CPU backends. The host runtime must launch kernels, copy memory buffers, and enforce capability limits.

## 5. Threat and failure model

| Threat | Notes |
|--------|-------|
| Driver and kernel exploits | Outside the language trusted computing base. Capabilities cannot fix bad drivers. |
| Data exfiltration via GPU memory | Needs device-buffer taint rules. No host-log paths for `#[Secret]` data. |
| Denial of Service (DoS) via kernel occupancy | Device cycle and time quotas are difficult to build. |
| False portability | A "universal" binary that only operates on one vendor. |
| Python-binding relapse | Calling PyTorch from an FFI breaks the design intent. |

**This does not prevent:** incorrect math, incorrect reduction order, or bugs in vendor libraries.

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **FFI to CUDA C++** | Easy. Breaks the design spirit. Makes a capability hole (Section 6.3). |
| **CUDA only first** | Pragmatic first step. Change DESIGN from "universal" to "phased". |
| **SYCL as sole path** | Portable on paper. Heavy C++ host dependency. |
| **Vulkan compute** | Portable. Hard to use. |
| **WebGPU** | Good for browsers. Does not meet all design goals. |
| **Postpone entirely** | Correct for the alpha release. The design stays a vision. |

## 7. Product reality

**PM.md row `4.1.3` is not-started.**

- The product does not emit PTX, ROCm, SPIR-V, or Metal.
- There is no GPU runtime in `chs_rt`.
- The self-host and smoke tests use the CPU Backend-C.

**Honesty rule:** Do not say that alpha openOODA accelerates tensors on the GPU. The design is a future goal only.

## 8. Open research questions

1. **Minimal kernel language subset** of `.oo`. There is no full CHS on the device.
2. **Unified vs discrete memory** capability model.
3. **NPU support** (Apple ANE, Qualcomm). These use vendor SDKs. They might not use a native compile path like LLVM.
4. **Determinism** for tests with GPU reductions.
5. **MLIR use.** Is MLIR mandatory, or is vendor SDK output enough for the first version?
6. **Interaction with holographic persistence (Section 4.4).** Device buffers are not NVMe-mapped structures.

## 9. Acceptance criteria

### not-started to smoke

- [ ] One backend creates code that runs. For example, PTX with driver launch or SPIR-V with runtime for a 1-D map kernel.
- [ ] A capability token is necessary to launch the kernel.
- [ ] Write a document to list the vendors that are not supported.

### smoke to partial

- [ ] Buffer allocate, copy, and free operations work with a memory quota.
- [ ] Continuous Integration runs on one hardware or a good emulator.
- [ ] Tests compare numeric results from the GPU and the CPU reference.

### partial to done

- [ ] Support a minimum of two backends (CUDA, ROCm, or SPIR-V/Metal), **or** change DESIGN to "phased multi-vendor".
- [ ] Give a public performance claim with benchmark tests.

## 10. References

1. CUDA Toolkit documentation (NVIDIA). https://developer.nvidia.com/cuda-toolkit
2. ENCCS GPU programming models overview (CUDA, ROCm, SYCL, Kokkos). https://enccs.github.io/gpu-programming/5-intro-to-gpu-prog-models/
3. SYCL and multi-vendor discussion. https://medium.com/@tonymongkolsmai/cuda-rocm-oneapi-running-code-on-a-gpu-any-gpu-28b7bf4cf1d0
4. MLIR `gpu` dialect. https://mlir.llvm.org/docs/Dialects/GPU/
5. ROCm migration literature. https://tensorwave.com/blog/transitioning-to-high-performance-a-comprehensive-guide-to-switching-from-cuda-to-rocm
6. openOODA: `DESIGN.md` Section 4; `PM.md` 4.1.3.

---

*Series: [Research papers index](./README.md). Related: [RP-4.1.2 LLVM](./RP-4-1-2-production-llvm.md).*
