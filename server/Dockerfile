FROM rust

WORKDIR /usr/src/myapp
COPY . .

RUN cargo install --path .

CMD ["./target/release/server"]
