# Runtime uses Ubuntu 24.04 so glibc >= 2.38 matches the bundled libclob_sdk.so
# (Ubuntu 22.04 / glibc 2.35 cannot load that prebuilt .so.)
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY src ./src

RUN cargo build --release

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder \
    /app/target/release/main_dual_limit_045_same_size \
    /app/target/release/main_dual_limit_045_5m_btc \
    /app/target/release/main_trailing \
    /app/target/release/backtest \
    /app/target/release/test_predict_fun \
    /app/target/release/test_sell \
    /app/target/release/test_redeem \
    /app/target/release/test_allowance \
    /app/target/release/test_limit_order \
    /app/target/release/test_merge \
    /app/target/release/test_cash_balance \
    /app/target/release/test_multiple_orders \
    /app/bin/

COPY lib/libclob_sdk.so /app/lib/libclob_sdk.so
COPY config.json /app/config.json

ENV RUST_LOG=info
ENTRYPOINT ["/app/bin/main_dual_limit_045_same_size"]
CMD ["--config", "/app/config.json"]
