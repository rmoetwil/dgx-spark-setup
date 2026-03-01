# vllm on the GB10

For running vllm I explored various options.

You can build it locally but until now I haven't found a clean solution yet.
I tried the [following](https://medium.com/@anveshkumarchavidi/installing-vllm-on-nvidia-dgx-spark-from-source-4dde137ff3ef) tutorial but this failed.

You can download the latest NVidia docker image but that one is lagging in updates quite a bit.

The AI landscape is changing so fast, new models are published every week. I found the setup from Eugr [vllm-spark-docker](https://github.com/eugr/spark-vllm-docker.git) the most convenient.
It has a so called recipes system where a bash script builds the docker image with the latest dependencies, applies patches if needed, downloads the llm model you would like to run and starts the vllm server and model with the given parameters.

Eugr also has a llama bench equivalent cli tool for benchmarking the vllm server. It's called [llama-benchy](https://github.com/eugr/llama-benchy).