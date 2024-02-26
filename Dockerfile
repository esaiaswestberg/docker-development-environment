FROM ubuntu:latest

# Update packages and install necessary tools
RUN apt-get update && \
    apt-get install -y openssh-server sudo tmux git curl gcc make zsh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up SSH
RUN mkdir /var/run/sshd && \
    echo 'root:password' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'UseDNS no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Setup Oh-My-Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="minimal"/' ~/.zshrc

# Expose SSH port
EXPOSE 22

# Install Neovim from pre-built archives
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz && \
    rm -rf /opt/nvim && \
    tar -C /opt -xzf nvim-linux64.tar.gz && \
    echo "export PATH=\"$PATH:/opt/nvim-linux64/bin\"" >> ~/.zshrc

# Install Neovim Kickstart
RUN git clone https://github.com/nvim-lua/kickstart.nvim.git /root/.config/nvim

# Automatically attach SSH sessions to tmux
RUN echo 'if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then tmux attach || tmux new; fi' >> /root/.zshrc

# Set Oh-My-Zsh as default shell for SSH connection
RUN sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config && \
    sed -i 's/#\?AcceptEnv.*/AcceptEnv LANG LC_* DISPLAY/' /etc/ssh/sshd_config && \
    echo "export LANG=C.UTF-8" >> /etc/default/locale && \
    echo "export LC_ALL=C.UTF-8" >> /etc/default/locale && \
    echo "export LANGUAGE=C.UTF-8" >> /etc/default/locale && \
    echo 'export SHELL=/bin/zsh' >> /etc/profile && \
    echo 'exec /bin/zsh -l' >> /etc/profile

# Start SSH
CMD ["/usr/sbin/sshd", "-D"]
