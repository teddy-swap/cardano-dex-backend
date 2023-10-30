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

RUN ghcup -v install ghc ${GHC} && \
    ghcup -v install cabal ${CABAL}
RUN ghcup set ghc $GHC
RUN ghcup set cabal $CABAL

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
RUN git clone https://github.com/teddy-swap/cardano-dex-backend.git /teddyswapbatcher

WORKDIR /teddyswapbatcher
# Cache dependencies
RUN cabal clean
RUN cabal update
RUN cabal configure --disable-tests --disable-benchmarks -f-scrypt -O2
RUN cp CHANGELOG.md amm-executor/CHANGELOG.md
RUN cp CHANGELOG.md wallet-helper/CHANGELOG.md
RUN cabal build all
ARG git_commit_id=master
RUN git fetch --all
RUN git checkout ${git_commit_id}
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN cabal update
RUN cabal build all
RUN cabal install amm-executor-app

FROM ubuntu:22.04
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN apt-get update -y && apt-get upgrade -y && apt-get install librocksdb-dev libnuma-dev x509-util curl -y
RUN x509-util system
# TEST CARDANO EXPLORER
RUN curl https://80-hallowed-priority-28uow9.us1.demeter.run/cardano/preview/v1/networkParams
COPY --from=builder /usr/lib/llvm-13 /usr/lib/llvm-13
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /root/.cabal/store/ghc-8.10.7 /root/.cabal/store/ghc-8.10.7
COPY --from=builder /root/.cabal/bin /root/.cabal/bin
COPY ./scripts /scripts
COPY ./config /config/cardano

ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV CONFIG_PATH="/mnt/spectrum/config.dhall"
ENTRYPOINT /root/.cabal/bin/amm-executor-app $CONFIG_PATH