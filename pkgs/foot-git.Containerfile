FROM debian:trixie-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    meson \
    ninja-build \
    pkg-config \
    gcc \
    dpkg-dev \
    scdoc \
    libwayland-dev \
    wayland-protocols \
    libxkbcommon-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libpixman-1-dev \
    libutf8proc-dev \
    ca-certificates

WORKDIR /build

RUN git clone --depth 1 \
    https://codeberg.org/dnkl/foot.git /tmp/foot && \
    git clone --depth 1 https://codeberg.org/dnkl/tllist.git /tmp/foot/subprojects/tllist && \
    git clone --depth 1 https://codeberg.org/dnkl/fcft.git  /tmp/foot/subprojects/fcft

RUN FOOT_VERSION="$(git -C /tmp/foot describe --tags --always)" && \
    echo "Building foot ${FOOT_VERSION}" && \
    mkdir -p /pkg/DEBIAN && \
    printf '%s\n' \
    "Package: foot-git" \
    "Version: ${FOOT_VERSION}" \
    "Section: x11" \
    "Priority: optional" \
    "Architecture: $(dpkg --print-architecture)" \
    "Maintainer: JumpyVi <jumpyvi@outlook.com>" \
    "Depends: libwayland-client0, libxkbcommon0, libfontconfig1, libfreetype6, libpixman-1-0, libutf8proc3" \
    "Description: A fast, lightweight and minimalistic Wayland terminal emulator (git version)" \
    > /pkg/DEBIAN/control

RUN meson setup /tmp/foot/build /tmp/foot \
    --buildtype=release \
    --prefix=/usr \
    -Dterminfo=disabled && \
    ninja -C /tmp/foot/build && \
    DESTDIR=/pkg ninja -C /tmp/foot/build install

RUN mkdir -p /out && \
    dpkg-deb --build /pkg /out/foot-git_$(dpkg --print-architecture).deb

FROM scratch AS export
COPY --from=builder /out .