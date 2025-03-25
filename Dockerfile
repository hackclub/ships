FROM rust

WORKDIR /usr/src/myapp
COPY . .

RUN cargo install --path server

CMD ["./server/target/release/server"]
