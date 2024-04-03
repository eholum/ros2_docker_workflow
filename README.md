# Containerized ROS 2 Development

Developing with ROS on an arm mac is... painful.
This little project aims to be a generic developer workflow for ROS environments that doesn't require VMs or additional work on a macbook.
Someday GitHub will add arm support and building a base environment from scratch every time won't be necessary.

I use this workflow to avoid having to install ros natively on my machine by mounting workspaces into a pre-built ros
development environment.
This way I can get started working with a ros project quickly, even if it does not have or has a broken docker developer workflow.

## Prerequisites

- Docker
- XQuartz
- Mesa Drivers (either with homebrew or: https://docs.mesa3d.org/macos.html)

Be sure to give containers display access with: `xhost +localhost`, prior to launch.

## Launching

Change the default user info in the compose file to match your system setup.

Then set a workspace to mount into the container.

```
# Build the base image
$ docker compose build develop

# Launch a container with a new workspace
$ export ROS_WORKSPACE=${SOME_WORKSPACE}
$ docker compose up develop -d

# Do stuff
$ docker compose exec develop bash
```

## Notes

#### Gazebo is still broken

Right now I'm testing the graphical environment with `xclock` and `glxheads`.
They can be installed in the container after launch with,

```
$ sudo apt install mesa-utils x11-apps
```

With this setup graphics acceleration is working fine but gz still segfaults for a variety of reasons.
