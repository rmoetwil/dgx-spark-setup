# DGX Spark

Below a list of changes I applied after booting the DGC Spark the first time.

- Install VSCode
- Install Cursor
- Install `uv` (I believe it was already installed)
- Make an alias for `nvitop` as the current version doesn't shod GPU memory correctly. (`alias nvitop='uvx nvitop'`)
- Add the current user to the group docker so you can use docker commands without sudo. (`sudo usermod -aG docker $USER`)
- Install Nvidia Sync on client machines