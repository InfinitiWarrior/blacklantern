# Dockerfile for BlackLantern

FROM kalilinux/kali-rolling

LABEL maintainer="InfintiWarrior"
LABEL description="BlackLantern - Offensive Security Toolkit"

# Update and install base tools
RUN apt update && apt upgrade -y && \
    apt install -y \
    figlet \
    net-tools \
    iputils-ping \
    curl \
    git \
    nmap \
    sqlmap \
    hydra \
    nikto \
    aircrack-ng \
    tmux \
    zsh \
    nano \
    gcc \
    make \
    sudo && \
    apt clean

# Copy startup script
COPY run.sh /root/run.sh
RUN chmod +x /root/run.sh

# Set shell prompt with figlet banner
RUN echo 'figlet "BlackLantern"' >> /root/.bashrc

WORKDIR /root
CMD ["bash"]
