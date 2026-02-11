# Build the GPU version of llama.cpp on GB10


## Build

For this follow this [documentation](https://learn.arm.com/learning-paths/laptops-and-desktops/dgx_spark_llamacpp/2_gb10_llamacpp_gpu/)


In short:
- Clone the llama.cpp repository
- Configure and build the CUDA-enabled version (GPU Mode)

```
cd ~
git clone https://github.com/ggerganov/llama.cpp.git
cd ~/llama.cpp

mkdir -p build-gpu
cd build-gpu
cmake .. \
	-DCMAKE_BUILD_TYPE=Release \
	-DGGML_CUDA=ON \
	-DGGML_CUDA_F16=ON \
	-DCMAKE_CUDA_ARCHITECTURES=121 \
	-DCMAKE_C_COMPILER=gcc \
	-DCMAKE_CXX_COMPILER=g++ \
	-DCMAKE_CUDA_COMPILER=nvcc
```

Optional changes:
- Add the `build-gpu/bin` directory to $PATH

## Run

```
llama-cli \
	-m ~/data/ai/models/TheBloke/TinyLlama-1.1B/tinyllama-1.1b-chat-v1.0.Q8_0.gguf \
	-ngl 32 \
	-t 16 \
	-p "Explain the advantages of the Armv9 architecture."
```


```
llama-server \
    -c 2048 --host 0.0.0.0 --port 8080 \
	-m ~/data/ai/models/TheBloke/TinyLlama-1.1B/tinyllama-1.1b-chat-v1.0.Q8_0.gguf \
	-ngl 999
```

Access llama.cpp webui via `http://localhost:8080`