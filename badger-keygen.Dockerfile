FROM ubuntu:22.04 as builder

RUN apt-get update -y && apt-get upgrade -y && apt-get install librocksdb-dev git liblzma-dev libnuma-dev curl automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf libncurses-dev clang llvm-13 llvm-13-dev -y

# GHCUP
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
RUN bash -c "curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh"
RUN bash -c "curl -sSL https://get.haskellstack.org/ | sh"

# Add ghcup to PATH
ENV PATH=${PATH}:/root/.local/bin
ENV PATH=${PATH}:/root/.ghcup/bin

# install GHC and cabal
ARG GHC=8.10.7
ARG CABAL=3.6.2.0

RUN \
    ghcup -v install ghc --isolate /usr/local --force ${GHC} && \
    ghcup -v install cabal --isolate /usr/local/bin --force ${CABAL}

# Cardano haskell dependencies
RUN git clone https://github.com/input-output-hk/libsodium
RUN cd libsodium && git checkout 66f017f1 && ./autogen.sh && ./configure && make && make install
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# libsecp256k1
RUN git clone https://github.com/bitcoin-core/secp256k1
RUN cd secp256k1 && git checkout ac83be33 && ./autogen.sh && ./configure --enable-module-schnorrsig --enable-experimental && make && make check && make install

ENV PATH=/usr/lib/llvm-13/bin:$PATH
RUN export CPLUS_INCLUDE_PATH=$(llvm-config --includedir):$CPLUS_INCLUDE_PATH
RUN export LD_LIBRARY_PATH=$(llvm-config --libdir):$LD_LIBRARY_PATH

ARG CACHE_BUST=2
ARG PASSWORD=password

RUN git clone https://github.com/teddy-swap/cardano-dex-backend.git /teddy-swap-batcher
WORKDIR /teddy-swap-batcher
RUN cabal clean
RUN cabal update
RUN cabal install key-gen
RUN apt-get install tree

FROM ubuntu:22.04 
COPY --from=builder /usr/lib/llvm-13 /usr/lib/llvm-13
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /root/.cabal/store/ghc-8.10.7/key-gen-*/bin /root/.cabal/store/ghc-8.10.7/key-gen/bin
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENTRYPOINT /root/.cabal/store/ghc-8.10.7/key-gen/bin/key-gen "/mnt/teddyswap/secret.json" "/mnt/teddyswap/payment.skey" $PASSWORD