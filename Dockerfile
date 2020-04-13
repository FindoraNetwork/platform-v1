FROM nexus.findora.org/zei:v0.0.2-4 as zei
FROM rustlang/rust:nightly-buster as builder
RUN cargo install cargo-audit
RUN cargo install wasm-pack
RUN mkdir /app
WORKDIR /app/
COPY --from=zei /app /src/zei
COPY --from=zei /src/zcash-bn-fork /src/zcash-bn-fork
COPY . /app/
RUN cargo audit
RUN cargo build --release
RUN cargo test --release --no-fail-fast --workspace --exclude 'txn_cli'
WORKDIR /app/components/wasm
RUN wasm-pack build --target nodejs
RUN bash -c 'time /app/target/release/log_tester /app/components/log_tester/example_log - /app/components/log_tester/expected'
#Cleanup some big files in release directory
RUN rm -r /app/target/release/build /app/target/release/deps

FROM debian:buster
COPY --from=builder /app/target/release /app
COPY --from=builder /app/components/wasm/pkg /app/wasm
WORKDIR /app/
CMD ls /app
