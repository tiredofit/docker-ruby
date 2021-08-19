# github.com/tiredofit/docker-ruby

# Introduction

Dockerfile to build a [ruby](https://www.ruby-lang.org/) base image.

* Currently tracking versions 2.3 and 2.4, 2.5, 2.6 in Debian and Alpine
* Includes Bundler
* [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 Init capabilities
* [zabbix-agent](https://zabbix.org) based on 3.4 for individual container monitoring.
* Cron installed along with other tools (bash,curl, less, logrotate, nano, vim) for easier management.

# Authors

- [Dave Conroy](https://github.com/tiredofit)

# Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Volumes](#data-volumes)
    - [Environment Variables](#environmentvariables)   
    - [Networking](#networking)
- [Maintenance](#maintenance)
    - [Shell Access](#shell-access)
   - [References](#references)

# Prerequisites

No prequisites required

# Installation

Automated builds of the image are available on [Docker Hub](https://hub.docker.com/tiredofit/ruby) and 
is the recommended method of installation.


```bash
docker pull tiredofit/ruby:(imagetag)
```

The following image tags are available:

* `2.3-debian:latest` - Ruby 2.3.x - Debian Linux
* `2.4-debian:latest` - Ruby 2.4.x - Debian Linux
* `2.5-debian:latest` - Ruby 2.5.x - Debian Linux
* `2.6-debian:latest` - Ruby 2.5.x - Debian Linux
* `2.3-alpine:latest` - Ruby 2.4.x - Alpine Linux
* `2.4-alpine:latest` - Ruby 2.4.x - Alpine Linux
* `2.5-alpine:latest` - Ruby 2.5.x - Alpine Linux
* `2.6-alpine:latest` - Ruby 2.6.x - Alpine Linux
* `latest` - Ruby 2.6.x - Alpine Linux


# Quick Start

Utilize this image as a base for further builds. By default it does not start the S6 Overlay system, but 
Bash. Please visit the [s6 overlay repository](https://github.com/just-containers/s6-overlay) for 
instructions on how to enable the S6 Init system when using this base or look at some of my other images 
which use this as a base.

# Configuration

### Environment Variables

Along with the Environment Variables from the [Base image](https://hub.docker.com/r/tiredofit/debian), below is the complete list of available options that can be used to customize your installation.

### Networking

No Additional Ports Exposed


# Maintenance
#### Shell Access

For debugging and maintenance purposes you may want access the containers shell. 

```bash
docker exec -it (whatever your container name is e.g. alpine) bash
```

# References

* https://www.alpinelinux.org
* https://www.debian.org
* https://www.ruby-lang.org/
