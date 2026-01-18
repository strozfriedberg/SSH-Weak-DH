# About

This tool creates SSH connections to a server and goes through different client
configurations to check if the server permits a Diffie-Hellman (DH) key
exchange using a weak group. We aim for our tool to help assess SSH servers for
weak DH key exchange settings.

Please be aware that this tool tests a limited set of configurations, which
might result in some weak configurations going undetected. Additionally, the
server might block connections before the scan finishes.

Consult the [Logjam info page](https://weakdh.org/sysadmin.html) for
suggestions on how to configure SSH servers to protect them as well as their
clients from attacks exploiting DH key exchanges using a weak group.

For the original blog post, visit
[https://blog.gdssecurity.com/labs/2015/8/3/ssh-weak-diffie-hellman-group-identification-tool.html](https://web.archive.org/web/20220107152429/http://blog.gdssecurity.com/labs/2015/8/3/ssh-weak-diffie-hellman-group-identification-tool.html).

# Installation

1. Install Podman or Docker.
2. Run one of the following commands to build the container image:
```shell
podman build -t ssh-weak-dh .
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ssh-weak-dh .
```

# Usage

## Scan

Run one of the following commands:
```shell
podman run --userns=keep-id:uid=65532,gid=65532 --name ssh-weak-dh --rm -v "$(pwd)/logs/":/logs/ ssh-weak-dh host [port]
docker run --name ssh-weak-dh --rm -v "$(pwd)/logs/":/logs/ ssh-weak-dh host [port]
```
- `host`: Hostname or IP address of the SSH server.
- `port`: Optional SSH server port (default is `22`).

Scan results will be printed to stdout. Detailed results are saved in the
`./logs/` directory under a subfolder named `host-port`.

The scan tool calls the script `ssh-weak-dh-analyze.py` to analyze the scan
results stored in the aforementioned subfolder.

## Analyze Scan Results

The analysis script is a standalone tool that can be run as follows:
```shell
# Get a container shell:
podman run --userns=keep-id:uid=65532,gid=65532 --name ssh-weak-dh --rm -v "$(pwd)/logs/":/logs/ -it --entrypoint bash ssh-weak-dh
docker run --name ssh-weak-dh --rm -v "$(pwd)/logs/":/logs/ -it --entrypoint bash ssh-weak-dh

# Run the analysis script on logged scan results:
./ssh-weak-dh-analyze.py /logs/scanme.example.com-22/
```

## Stop

Stop a running container:
```shell
podman stop ssh-weak-dh
docker stop ssh-weak-dh
```

# License

This project is licensed under the GNU General Public License v2.0.
See [LICENSE](LICENSE) for details.

Copyright (C) 2015-2026 Fabian Foerg / Gotham Digital Science

