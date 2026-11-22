# promptfoo

[promptfoo](https://github.com/promptfoo/promptfoo) evaluates the quality of models on your own test cases.
Here it compares local models behind [llama-swap](llama-swap.md), side by side, and uses a local model as the judge for checks that need judgement.
Measure speed separately, for example with eugr's [llama-benchy](https://github.com/eugr/llama-benchy).

promptfoo is MIT-licensed and has been part of OpenAI since March 2026.
It sends usage telemetry by default; the wrapper below switches that off.

## Files

| Path in this repository | Purpose |
|---|---|
| `scripts/promptfoo-install.sh` | Install or upgrade Node.js and promptfoo in `~/.local/opt`, without sudo |
| `scripts/promptfoo-offline` | Run promptfoo with telemetry and other remote features switched off |
| `promptfoo/smoke/promptfooconfig.yaml` | Smoke test: promptfoo, llama-swap and two local models |

## Install

From the root of this repository:

```bash
scripts/promptfoo-install.sh                  # latest promptfoo, with the latest Node.js 24 LTS
ln -s "$PWD/scripts/promptfoo-offline" ~/.local/bin/promptfoo
```

The install script downloads the official Node.js linux-arm64 release, checks its checksum, and installs promptfoo with that Node.js.
Run it again to upgrade; pass a version, such as `scripts/promptfoo-install.sh 0.126.0`, to pin one.

npm may warn that it skipped the install script of `esbuild`.
Evaluations work without it.

## Offline settings

`promptfoo` in `~/.local/bin` is the wrapper `scripts/promptfoo-offline`, so promptfoo never runs without these settings:

| Variable | Effect |
|---|---|
| `PROMPTFOO_DISABLE_TELEMETRY=1` | No usage telemetry |
| `PROMPTFOO_DISABLE_UPDATE=1` | No update checks |
| `PROMPTFOO_DISABLE_REMOTE_GENERATION=true` | No test generation on promptfoo's servers |
| `PROMPTFOO_DISABLE_SHARING=1` | No sharing of results |
| `PROMPTFOO_SELF_HOSTED=1` | Self-hosted mode |
| `REQUEST_TIMEOUT_MS=600000` | Ten minutes per request, because llama-swap may first have to load a model |

promptfoo's own FAQ says these settings are not a firewall.
Block outbound traffic as well before using sensitive test cases.

## Run the smoke test

```bash
cd promptfoo/smoke
promptfoo eval -j 1 --no-cache
promptfoo view                                # web interface with the results, side by side
```

- **`-j 1`** runs one request at a time, so llama-swap loads one model at a time instead of switching back and forth.
- **`--no-cache`** sends every request to the model again; leave it out to reuse earlier answers.

### Smoke test results

Run on 2026-11-22 with promptfoo 0.126.0, Node.js 24.22.3 and llama-swap v275, on the DGX Spark itself:

- **All 6 checks passed:** 3 test cases for 2 models, including one `llm-rubric` check judged by `nemotron-nano`.
- **It took 3 minutes 42 seconds**, mostly loading models.
- **llama-swap loaded a model 6 times.** With `-j 1`, promptfoo runs the test cases one by one, and within each test case it asks both models in turn. Every test case therefore switches models twice. The judge calls ran at the end, while the judge model was already loaded.
- **Nemotron's answers start with its reasoning**, such as "Thinking: We need to answer...". Checks such as `contains` and `llm-rubric` also see that text.

### Fewer model switches

Every switch to a vLLM model takes about a minute, so many test cases mean a long run. Options to try:

- **Keep the models loaded together** with a llama-swap group that does not swap, if they fit in memory together. A small GGUF model next to one vLLM model may fit, because the vLLM recipe reserves only part of the memory.
- **Evaluate one model per run** with `promptfoo eval -j 1 --filter-providers <label>`, and compare the runs afterwards.

## Write your own evaluation

Create a folder per evaluation with its own `promptfooconfig.yaml`, and start from the smoke test:

- **`providers`:** the llama-swap models to compare, as `openai:chat:<model name in llama-swap>`, with `apiBaseUrl: http://127.0.0.1:9292/v1`.
- **`defaultTest.options.provider`:** the judge model for `llm-rubric` checks. Use one fixed model, so scores stay comparable.
- **`tests`:** the test cases, each with `vars` and `assert` checks:
  - `contains`, `icontains`, `regex` or `equals` for answers that can be checked exactly;
  - `llm-rubric` for answers that need judgement, judged by the local model;
  - `python` or `javascript` for custom checks, such as running a linter.

Keep test cases with sensitive content out of this public repository.
