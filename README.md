# Debian Base System

Build a Debian container image with Systemd, Postfix, Dovecot and SSH remote access
using Podman/Buildah.


## Run the image build

To build a Debian 11 Bookworm image run

```bash
./build-container.sh
```

To build an image with a specific Debian version
(`buster`, `bullseye`, `bookworm`) run

```bash
./build-container.sh bullseye
```

Without placing a `root/.ssh/authorized_keys` file in the project directory
the build script configures the SSH daemon for root access with the password
`admin`.  Otherwise SSH root login using a password is prohibited and restriced
to the given SSH keys.


## Run the container

Run the container with sshd listening on port 10022 for remote connections.

```bash
podman run --rm --detach --cap-add audit_write,audit_control -p=10022:22 localhost/debian-mail-bookworm
```

Connect per SSH (host keys are regenerated at each container start).

```bash
ssh -p 10022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@host.example.org
```


## Safety

Do not run `setup.sh` in your host system.
