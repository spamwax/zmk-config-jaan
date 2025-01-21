# syntax=docker/dockerfile:1.4
# vim: filetype=dockerfile
# use:
#    dk buildx build --target nix-base -t private/nix-zmk-base -f ./nix-zmk-base.dockerfile .

FROM debian:testing-slim AS nix-base
ARG zmk_type=dev
ARG zmk_tag=3.5
ARG ZMK_CONFIG_REPO

ARG USERNAME=hamid
ARG USERUID=1000
ARG USERGID=1000

ENV USER_ID=$USERUID
ENV GROUP_ID=$USERGID
ENV USER_NAME=$USERNAME

RUN apt -y update && apt -y upgrade
RUN apt install -y curl wget build-essential git
RUN apt install -y cmake ninja-build bash-completion jq yq htop neovim openssh-client shellcheck reserialize
RUN apt install -y sudo passwd bsdextrautils
RUN wget https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.aarch64.tar.xz \
    && tar -xvf shellcheck-stable.linux.aarch64.tar.xz \
    && cp ./shellcheck-stable/shellcheck $(which shellcheck)

RUN groupadd --gid $GROUP_ID $USER_NAME \
    && useradd --uid $USER_ID --gid $GROUP_ID -d /home/$USER_NAME -m $USER_NAME
# RUN usermod -aG nix-users ${USERNAME}
RUN usermod -aG sudo ${USERNAME}
RUN chown -R ${USERNAME}:${USERGID} /home/${USERNAME}
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}

RUN mkdir -p -m 0700 /home/${USERNAME}/.ssh && ssh-keyscan 192.168.13.200 >> /home/${USERNAME}/.ssh/known_hosts
RUN --mount=type=ssh \
    ssh -q -T ${USERNAME}@192.168.13.200 ls 2>&1 | tee /hello
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCd+h7PYcF4n3FgAX7roJHMTmytsBp2/FrVZM9H+zeCMPyRWfArfMVNofyBGGtqX9z+yyDsYWAu7YlD2bjj7sHDD+PJyeNRI5lsAngGEzXHxwm3mAXUgj45Q6mgm2JS9M4c468bUd/rp8LicYdxDXYv71HdaRkkRW+O+JOvewCRoHQW8+5otoHIy3kyHSRwtkZ7qMAkDH6Q9yhvylFsAKX+Ox15whLAKVniVehIi9EMwhFSbY+/J8k8Z17aZytpz+q6ieUj5gt2b+YRHrcvoLblCVpQKeZwHTpEMhIHcpv8/1LZZ31G0p48p9r4o3JJ8ecAFSG/1E/pkWrXnc9Ga3uqWehjhI+opX0ZC1hA6LGpoNatOWU6QYXBy0qV9YRT/6AZvfYjKMzHTxb92F4TGB3WlaDhC/D4gg2eFKdXzRIF6Ay5eta1nIhGmwKyD0BRByY5dFxnW5dfMWqRoR0YA7r/2mABFh9qN+KTISx/H1wq+WJprnv3PsV9siQ0eEZk5IM= hamid@khersak" > /home/${USERNAME}/.ssh/id_rsa.pub
RUN echo ".DS_Store\n.DS_Store\n*.o\n*.pyc\n*.idea\n.vscode\nnode_modules\ntarget/**/build\ntarget/**/debug\ntarget/**/release\n*.swp\nSession.vim" > /home/${USERNAME}/.gitignore_global

# Switch to bash for the build stage
RUN chsh -s /bin/bash root
SHELL ["/bin/bash", "-c"]
# Install Nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm
