![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/cliamp-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/cliamp-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/cliamp-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/cliamp-debian)

<h1>
   <p align="center">
     <a href="https://cliamp.stream"><img src="https://github.com/dariogriffo/cliamp-debian/blob/main/cliamp.png" alt="cliamp Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/cliamp-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>cliamp for Debian
   </p>
</h1>
<p align="center">
 cliamp is a retro terminal music player inspired by Winamp 2.x.
</p>

# cliamp for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [cliamp](https://github.com/bjarneo/cliamp/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Jammy (22.04)
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64)
- arm64 (aarch64)

Upstream publishes no i386, armel, armhf or riscv64 binaries, so those
architectures are not available.

The packages include the cliamp binary, a man page, a desktop entry with the
application icon, and shell completions for bash and zsh.

> ℹ️ Fish completions are **not** shipped. Upstream's CLI library renders a
> broken fish template (it contains literal `%!(BADWIDTH)` markers), so
> installing it would only break fish sessions.

The player links against ALSA, and pulls in `ffmpeg` as a recommendation for
the formats it shells out for, plus `yt-dlp` as a suggestion for YouTube and
YouTube Music playback.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the cliamp source code, see
[cliamp](https://github.com/bjarneo/cliamp/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-cliamp-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-cliamp-in-ubuntu.html)

### The Debian way

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/cliamp-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y cliamp
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/cliamp-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

> ℹ️ cliamp ships an `upgrade` command that replaces its own binary. On Debian
> and Ubuntu, use `apt` instead so the package manager stays in charge of the
> installed files.

## Building

### Build for single architecture
```sh
./build.sh <cliamp_version> <build_version> <architecture>
# Example: ./build.sh 1.63.2 1 arm64
```

### Build for all architectures
```sh
./build.sh <cliamp_version> <build_version> all
# Example: ./build.sh 1.63.2 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64)

## Disclaimer

- This repo is not open for issues related to cliamp. This repo is only for _unofficial_ Debian packaging.
