# Ubuntu release versions 18.04 and 20.04 are supported
ARG UBUNTU_RELEASE=20.04
ARG CUDA_VERSION=11.2.2
FROM nvcr.io/nvidia/cudagl:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_RELEASE}

LABEL maintainer "https://github.com/ehfd,https://github.com/danisla"

ARG UBUNTU_RELEASE
ARG CUDA_VERSION
# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
# Supress interactive menu while installing keyboard-configuration
ARG DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES all
ENV PULSE_SERVER 127.0.0.1:4713

# Default environment variables (password is "mypasswd")
ENV TZ UTC
ENV REFRESH 60
ENV PASSWD mypasswd
ENV NOVNC_ENABLE false
ENV WEBRTC_ENCODER nvh264enc
ENV WEBRTC_ENABLE_RESIZE false
ENV ENABLE_AUDIO false
ENV ENABLE_BASIC_AUTH true

# Temporary fix for NVIDIA container repository
RUN apt-get clean && \
    apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/$(cat /etc/os-release | grep '^ID=' | awk -F'=' '{print $2}')$(cat /etc/os-release | grep '^VERSION_ID=' | awk -F'=' '{print $2}' | sed 's/[^0-9]*//g')/x86_64/3bf863cc.pub" && \
    rm -rf /var/lib/apt/lists/*

# Install locales to prevent errors
RUN apt-get clean && \
    apt-get update && apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Xvfb, Xfce Desktop, and others
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install --no-install-recommends -y \
        software-properties-common \
        apt-transport-https \
        apt-utils \
        build-essential \
        ca-certificates \
        cups-filters \
        cups-common \
        cups-pdf \
        curl \
        file \
        wget \
        bzip2 \
        gzip \
        p7zip-full \
        xz-utils \
        zip \
        unzip \
        zstd \
        gcc \
        git \
        jq \
        make \
        python \
        python-numpy \
        python3 \
        python3-cups \
        python3-numpy \
        mlocate \
        nano \
        vim \
        htop \
        firefox \
        transmission-gtk \
        qpdfview \
        xarchiver \
        brltty \
        brltty-x11 \
        desktop-file-utils \
        fonts-dejavu-core \
        fonts-freefont-ttf \
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-cjk-extra \
        fonts-noto-color-emoji \
        fonts-noto-hinted \
        fonts-noto-mono \
        fonts-opensymbol \
        fonts-symbola \
        fonts-ubuntu \
        gucharmap \
        mpd \
        onboard \
        orage \
        parole \
        policykit-desktop-privileges \
        libpulse0 \
        pavucontrol \
        ristretto \
        supervisor \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        net-tools \
        libgtk-3-bin \
        vainfo \
        vdpauinfo \
        mesa-utils \
        mesa-utils-extra \
        xdg-utils \
        dbus-x11 \
        libdbus-c++-1-0v5 \
        dmz-cursor-theme \
        numlockx \
        xcursor-themes \
        xvfb \
        xubuntu-artwork \
        xfburn \
        xfpanel-switch \
        xfce4 \
        xfdesktop4 \
        xfwm4 \
        xfce4-appfinder \
        xfce4-clipman \
        xfce4-dict \
        xfce4-goodies \
        xfce4-notes \
        xfce4-notifyd \
        xfce4-panel \
        xfce4-screenshooter \
        xfce4-session \
        xfce4-settings \
        xfce4-taskmanager \
        xfce4-terminal \
        xfce4-appmenu-plugin \
        xfce4-battery-plugin \
        xfce4-clipman-plugin \
        xfce4-cpufreq-plugin \
        xfce4-cpugraph-plugin \
        xfce4-diskperf-plugin \
        xfce4-datetime-plugin \
        xfce4-fsguard-plugin \
        xfce4-genmon-plugin \
        xfce4-indicator-plugin \
        xfce4-mpc-plugin \
        xfce4-mount-plugin \
        xfce4-netload-plugin \
        xfce4-notes-plugin \
        xfce4-places-plugin \
        xfce4-sensors-plugin \
        xfce4-smartbookmark-plugin \
        xfce4-statusnotifier-plugin \
        xfce4-systemload-plugin \
        xfce4-timer-plugin \
        xfce4-verve-plugin \
        xfce4-weather-plugin \
        xfce4-whiskermenu-plugin \
        xfce4-xkb-plugin && \
    apt-get install -y libreoffice && \
    cp -rf /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    # Support libva and VA-API through NVIDIA VDPAU
    curl -fsSL -o /tmp/vdpau-va-driver.deb "https://launchpad.net/~saiarcot895/+archive/ubuntu/chromium-dev/+files/vdpau-va-driver_0.7.4-6ubuntu2~ppa1~18.04.1_amd64.deb" && apt-get install --no-install-recommends -y /tmp/vdpau-va-driver.deb && rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

# Install Vulkan (for offscreen rendering only)
RUN if [ "${UBUNTU_RELEASE}" = "18.04" ]; then apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-utils; else apt-get update && apt-get install --no-install-recommends -y libvulkan1 vulkan-tools; fi && \
    rm -rf /var/lib/apt/lists/* && \
    VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -p /etc/vulkan/icd.d/ && \
    echo "{\n\
    \"file_format_version\" : \"1.0.0\",\n\
    \"ICD\": {\n\
        \"library_path\": \"libGLX_nvidia.so.0\",\n\
        \"api_version\" : \"${VULKAN_API_VERSION}\"\n\
    }\n\
}" > /etc/vulkan/icd.d/nvidia_icd.json

# Install VirtualGL
RUN VIRTUALGL_VERSION=$(curl -fsSL "https://api.github.com/repos/VirtualGL/virtualgl/releases/67016359" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g') && \
    curl -fsSL -O https://sourceforge.net/projects/virtualgl/files/virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    curl -fsSL -O https://sourceforge.net/projects/virtualgl/files/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb ./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    rm virtualgl_${VIRTUALGL_VERSION}_amd64.deb virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    chmod u+s /usr/lib/libvglfaker.so && \
    chmod u+s /usr/lib/libdlfaker.so && \
    chmod u+s /usr/lib32/libvglfaker.so && \
    chmod u+s /usr/lib32/libdlfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libvglfaker.so && \
    chmod u+s /usr/lib/i386-linux-gnu/libdlfaker.so

# Install Python application, and web application
RUN apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        python3-pip \
        python3-dev \
        python3-gi \
        python3-setuptools \
        python3-wheel \
        tzdata \
        sudo \
        udev \
        xclip \
        x11-utils \
        xdotool \
        wmctrl \
        jq \
        gdebi-core \
        x11-xserver-utils \
        xserver-xorg-core \
        libopus0 \
        libgdk-pixbuf2.0-0 \
        libsrtp2-1 \
        libxdamage1 \
        libxml2-dev \
        libcairo-gobject2 \
        libpulse0 \
        libpangocairo-1.0-0 \
        libgirepository1.0-dev \
        libjpeg-dev \
        zlib1g-dev \
        x264 && \
    rm -rf /var/lib/apt/lists/*

# Install latest noVNC web interface for fallback
RUN apt-get update && apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        autotools-dev \
        chrpath \
        debhelper \
        jq \
        python \
        python-numpy \
        python3 \
        python3-numpy \
        libc6-dev \
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libssl-dev \
        libv4l-dev \
        libvncserver-dev \
        libtool-bin \
        libxdamage-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxss-dev \
        libxtst-dev \
        libavahi-client-dev && \
    rm -rf /var/lib/apt/lists/* && \
    X11VNC_VERSION=$(curl -fsSL "https://api.github.com/repos/LibVNC/x11vnc/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g') && \
    curl -fsSL https://github.com/LibVNC/x11vnc/archive/${X11VNC_VERSION}.tar.gz | tar -xzf - -C /tmp && \
    cd /tmp/x11vnc-${X11VNC_VERSION} && autoreconf -fi && ./configure && make install && cd / && rm -rf /tmp/* && \
    NOVNC_VERSION=$(curl -fsSL "https://api.github.com/repos/noVNC/noVNC/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g') && \
    curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Add custom packages below this comment
# python 3.9 conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV PATH /opt/conda/bin:$PATH

# java jdk 1.8
RUN apt update -y && apt install -y software-properties-common && \
    add-apt-repository ppa:openjdk-r/ppa && apt update -y && \
    apt install -y openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

# install MineDojo
RUN pip3 install --no-cache-dir git+https://github.com/MineDojo/MineDojo

# Create user with password ${PASSWD}
RUN apt-get update && apt-get install --no-install-recommends -y \
        sudo && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1000 user && \
    useradd -ms /bin/bash user -u 1000 -g 1000 && \
    usermod -a -G adm,cdrom,dialout,dip,fax,floppy,input,lp,lpadmin,plugdev,sudo,tape,tty,video,voice user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown user:user /home/user && \
    echo "user:${PASSWD}" | chpasswd && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod 755 /etc/entrypoint.sh

EXPOSE 8080

USER user
ENV USER=user
WORKDIR /home/user

ENV DISPLAY :0
ENV VGL_REFRESHRATE 60
ENV VGL_ISACTIVE 1
ENV VGL_DISPLAY egl
ENV VGL_WM 1

ENTRYPOINT ["/etc/entrypoint.sh"]
