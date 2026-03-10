I want a setup that will run claude  code in a sandbox so it can't modify, create or remove files outside its environment. 
- create a bash script that will start Docker where only a single project directory is bind-mounted  (e.g. -v "$PWD":/workspace in Docker). 
- the script should bind-mount the current directory.
- the container will run Ubuntu Server LTS
- the container will load any  additional applications to support running "claude code" inside the container
- Run claude inside that environment so the only visible writable tree is /workspace (your top‑level dir).

