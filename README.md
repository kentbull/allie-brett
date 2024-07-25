# Heartnet KLI Sign and Verify Tutorial

## Usage

### Docker

```bash
docker build --no-cache -t kentbull/heartnet:latest .
docker run --rm -it --entrypoint /bin/bash kentbull/heartnet
```
Then, within the container, either run the commands from the blog post or run the following script.

```bash
./heartnet-docker-workflow.sh
```

### Bash Script
Run the following Bash command after installing KERI on your system so you have the `kli` command available (test with `kli version`).
```bash
./heartnet-cli-workflow.sh
```