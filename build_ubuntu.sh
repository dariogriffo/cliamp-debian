#!/bin/bash
cliamp_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$cliamp_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <cliamp_version> <build_version> [architecture]"
    echo "Example: $0 1.63.2 1 arm64"
    echo "Example: $0 1.63.2 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Upstream tags carry a "v" prefix (e.g. v1.63.2) and the release assets are
# bare binaries named cliamp-linux-<goarch>, not tarballs.
UPSTREAM_URL="https://github.com/bjarneo/cliamp/releases/download/v${cliamp_VERSION}"
RAW_URL="https://raw.githubusercontent.com/bjarneo/cliamp/v${cliamp_VERSION}"

# Completions are generated from the amd64 binary; the scripts are plain shell
# templates and are identical on every architecture.
COMPLETIONS_ARCH="amd64"

# Map a Debian architecture to the Go architecture used in the asset name.
# Upstream publishes linux/amd64 and linux/arm64 only, and both are cgo builds
# needing GLIBC_2.34 at most, so they run on every suite we target.
get_goarch() {
    case "$1" in
        "amd64") echo "amd64" ;;
        "arm64") echo "arm64" ;;
        *)       echo "" ;;
    esac
}

# The desktop entry and the icon are taken from the upstream tag so they always
# match the packaged release.
fetch_assets() {
    if [ -f assets/cliamp.desktop ] && [ -f assets/cliamp.png ]; then
        echo "Using existing assets/"
        return 0
    fi

    echo "Downloading desktop entry and icon from v${cliamp_VERSION}..."
    mkdir -p assets

    if ! wget -q "${RAW_URL}/cliamp.desktop" -O assets/cliamp.desktop; then
        echo "❌ Failed to download cliamp.desktop"
        return 1
    fi
    if ! wget -q "${RAW_URL}/Cliamp.png" -O assets/cliamp.png; then
        echo "❌ Failed to download Cliamp.png"
        return 1
    fi

    for f in assets/cliamp.desktop assets/cliamp.png; do
        if [ ! -s "$f" ]; then
            echo "❌ Asset $f is empty"
            return 1
        fi
    done
    echo "✅ Assets downloaded"
}

# Generate the shell completions once, from the amd64 binary.
# Fish is deliberately skipped: upstream's CLI library renders a broken fish
# template (literal "%!(BADWIDTH)" markers), so shipping it would only break
# fish sessions.
generate_completions() {
    if [ -f completions/cliamp.bash ] && [ -f completions/_cliamp ]; then
        echo "Using existing completions/"
        return 0
    fi

    echo "Generating shell completions from cliamp-linux-${COMPLETIONS_ARCH}..."
    rm -rf .completions-gen completions || true
    mkdir -p .completions-gen completions

    if ! wget -q "${UPSTREAM_URL}/cliamp-linux-${COMPLETIONS_ARCH}" -O .completions-gen/cliamp; then
        echo "❌ Failed to download cliamp-linux-${COMPLETIONS_ARCH} for completion generation"
        return 1
    fi
    chmod +x .completions-gen/cliamp

    ./.completions-gen/cliamp completion bash > completions/cliamp.bash
    ./.completions-gen/cliamp completion zsh  > completions/_cliamp
    rm -rf .completions-gen

    for f in completions/cliamp.bash completions/_cliamp; do
        if [ ! -s "$f" ]; then
            echo "❌ Completion file $f is empty"
            return 1
        fi
    done
    echo "✅ Completions generated"
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local goarch

    goarch=$(get_goarch "$build_arch")
    if [ -z "$goarch" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using cliamp-linux-$goarch"

    # Clean up any previous download for this architecture
    rm -rf "dist/$build_arch" || true
    mkdir -p "dist/$build_arch"

    if ! wget "${UPSTREAM_URL}/cliamp-linux-${goarch}" -O "dist/$build_arch/cliamp"; then
        echo "❌ Failed to download cliamp binary for $build_arch"
        return 1
    fi

    if [ ! -s "dist/$build_arch/cliamp" ]; then
        echo "❌ Downloaded cliamp binary for $build_arch is empty"
        return 1
    fi
    chmod +x "dist/$build_arch/cliamp"

    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$cliamp_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "cliamp-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg cliamp_VERSION="$cliamp_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "cliamp-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/cliamp_$FULL_VERSION.deb" - > "./cliamp_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./cliamp_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    rm -rf "dist/$build_arch" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if ! fetch_assets; then
    exit 1
fi

if ! generate_completions; then
    exit 1
fi

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building cliamp $cliamp_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # Upstream publishes linux/amd64 and linux/arm64 only
    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la cliamp_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
