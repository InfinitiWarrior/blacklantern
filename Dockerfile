# Use the official Kali Linux base image
FROM kalilinux/kali-rolling

# Set the maintainer and description
LABEL maintainer="InfinitiWarrior"
LABEL description="BlackLantern - Offensive Security Toolkit"

# Update and install necessary packages
RUN apt update && apt upgrade -y && \
    apt install -y \
    nmap \
    masscan \
    amass \
    theharvester \
    whatweb \
    dnsenum \
    dnsrecon \
    sublist3r \
    dirb \
    gobuster \
    ffuf \
    feroxbuster \
    hydra \
    sqlmap \
    nikto \
    metasploit-framework \
    binwalk \
    bettercap \
    beef-xss \
    responder \
    crackmapexec \
    impacket-scripts \
    socat \
    curl \
    wget \
    jq \
    tmux \
    gcc \
    clang \
    make \
    python3 \
    python3-pip \
    bash \
    zsh \
    nano \
    vim \
    figlet \
    cowsay \
    sudo \
    aircrack-ng \
    ethtool \
    tcpdump \
    wireshark \
    netcat-traditional \
    smbclient \
    gdb \
    gdbserver \
    strace \
    ltrace \
    radare2 \
    ghidra \
    iputils-ping \
    net-tools \
    iproute2 \
    rsync \
    ufw \
    hostname \
    binutils \
    ettercap-text-only \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Install additional tools like LinPEAS and SearchSploit from GitHub
RUN git clone https://github.com/carlospolop/PEASS-ng.git /root/PEASS-ng && \
    git clone https://github.com/rapid7/metasploit-framework.git /root/metasploit-framework && \
    ln -s /root/metasploit-framework/msfvenom /usr/local/bin/msfvenom && \
    git clone https://github.com/offensive-security/exploitdb.git /root/exploitdb && \
    ln -s /root/exploitdb/searchsploit /usr/local/bin/searchsploit

# Copy the blacklantern.sh script to the container
COPY blacklantern.sh /root/blacklantern.sh
RUN chmod +x /root/blacklantern.sh
# Set the prompt using figlet for a customized banner
RUN echo 'figlet "BlackLantern"' >> /root/.bashrc

# Set working directory to /root
WORKDIR /root

# Set the default command to bash
CMD ["bash"]
