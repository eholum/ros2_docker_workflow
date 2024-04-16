# Dockerfile for building ROS 2 environments on the Ubuntu.
# Defaults to iron.
ARG ROS_DISTRO=iron

# Override these
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Base ROS image
FROM ubuntu:jammy AS ros-base

# Fast fail on random bash commands
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

ARG ROS_DISTRO
ARG SYNC_DATESTAMP
ARG DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO ${ROS_DISTRO}
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Install base deps
RUN apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata \
    software-properties-common \
    locales \
    curl \
    git \
    dirmngr \
    lsb-release \
    wget \
    gnupg2 \
    sudo

# Enable zram for goodness' sake
RUN apt-get install -q -y --no-install-recommends zram-config

# Install ros
RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu \
        $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2-${ROS_DISTRO}.list > /dev/null

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-ros-core \
        ros-${ROS_DISTRO}-ros-base

# Overlay developer setup
FROM ros-base AS ros-develop

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

ARG USER_HOME=/home/${USERNAME}/
ENV USER_HOME=${USER_HOME}
WORKDIR $USER_HOME

# Create a new user
RUN groupadd --gid $USER_GID ${USERNAME} && \
    useradd --uid $USER_UID --gid $USER_GID --shell /bin/bash --create-home ${USERNAME} && \
    mkdir -p \
      /home/${USERNAME}/.ccache \
      /home/${USERNAME}/.colcon \
      /home/${USERNAME}/.ros

# Give them passwordless root
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

# Install additional dev tools
RUN sudo apt-get update && \
    sudo apt-get install -q -y --no-install-recommends \
        git \
        git-lfs \
        build-essential \
        python3-colcon-common-extensions \
        python3-colcon-mixin \
        python3-rosdep \
        python3-vcstool \
        lld \
        vim \
        ccache \
        clang \
        clangd

# Add defaults and update userhome perms
COPY colcon-defaults.yaml ${USER_HOME}/.colcon/defaults.yaml
RUN sudo chown -R ${USERNAME}:${USERNAME} ${USER_HOME}

# Set up colcon
RUN colcon mixin add default \
    https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
    https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update

# Do sad things
RUN sudo rosdep init && rosdep update --rosdistro ${ROS_DISTRO}

# Set the entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod a+x /entrypoint.sh
RUN echo "source /entrypoint.sh" >> ~/.bashrc
ENTRYPOINT ["/entrypoint.sh"]
