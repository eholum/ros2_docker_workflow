# Dockerfile for building ROS 2 environments on the Ubuntu.
# Defaults to iron.
ARG ROS_DISTRO=iron

# Base ROS image
FROM ubuntu:jammy AS ros-base

# Fast fail on random bash commands
SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

ARG ROS_DISTRO
ARG SYNC_DATESTAMP
ARG DEBIAN_FRONTEND=noninteractive

ENV ROSDISTRO_INDEX_URL "https://raw.githubusercontent.com/ros/rosdistro/${ROS_DISTRO}/${SYNC_DATESTAMP}/index-v4.yaml"
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
    sudo

RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu \
        $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2-${ROS_DISTRO}.list > /dev/null

# Install the core
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-ros-core

# Setup tools
RUN apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        git \
        git-lfs \
        python3-colcon-common-extensions \
        python3-colcon-mixin \
        python3-rosdep

# Setup colcon
RUN colcon mixin add default \
    https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
    https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update

# Install the rest of that bad boi
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-ros-base

CMD /bin/bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN echo "source /entrypoint.sh" >> ~/.bashrc
ENTRYPOINT ["/entrypoint.sh"]
