# DGX Spark Setup

Repository containing info, scripts etc for working on my DGX Spark machine


## My explorations so far

Building llama.cpp from source is very easy.

I created a project for running `llama.cpp` or `vllm` with models of choice using some python scripts, the hugging face download library and using docker-compose.

While this is a nice exploration on it's own, if you just want to get an llm running with minimal effort I would go for Eugr recipes system. See my other doc on setting up vllm or ...

They also launched [Spark Arena](https://spark-arena.com/) where you see some performance stats for models run on one or two DGX Spark instances.


## Python scripts

The python scripts are just code snippets I used for testing various llm servers.
