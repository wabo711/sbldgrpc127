FROM ubuntu:20.04

# タイムゾーン選択を回避するため、先にインストール
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata && apt-get clean -y
ENV TZ=Asia/Tokyo 

#
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bash-completion \
    build-essential \
    cmake \
    curl \
    gdb \
    gdbserver \
    git \
    g++ \
    libtool \
    libssl-dev \
    make \
    pkg-config \
    openssh-server \
    rsync \
    software-properties-common \
    sudo \
    unzip \
    uuid \
    uuid-dev \
    zlib1g-dev \
    && apt-get clean

# install gcc-9
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y g++-9-multilib \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 30 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 30 \
    && apt-get clean -y

# install protobuf first, then grpc
RUN git clone -b v1.27.x https://github.com/grpc/grpc /var/local/git/grpc && \
    cd /var/local/git/grpc && \
    git submodule update --init && \
    echo "--- installing protobuf ---" && \
    cd third_party/protobuf && \
    git submodule update --init && \
    ./autogen.sh && ./configure --enable-shared && \
    make && make check && make install && make clean && ldconfig && \
    echo "--- installing grpc ---" && \
    cd /var/local/git/grpc && \
    make && make install && make clean && ldconfig && \
    rm -rf /var/local/git/grpc

# uWS
RUN git clone -b v0.14.8 https://github.com/uNetworking/uWebSockets/ /var/local/git/uWS \
    && cd /var/local/git/uWS \
    && make && make install && make clean && ldconfig \
    && rm -rf /var/local/git/uWS

# googleTest
RUN git clone https://github.com/google/googletest.git /var/local/git/gtest \
    && cd /var/local/git/gtest \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && cp lib/lib*.a /usr/lib \
    && cd /var/local/git/gtest \
    && cp -r googletest/include/gtest /usr/include \
    && cp -r googlemock/include/gmock /usr/include \
    && rm -rf /var/local/git/gtest

# sshdの設定
RUN mkdir /run/sshd && \
    useradd -m -s /bin/bash ubuntu && gpasswd -a ubuntu sudo && \
    echo 'ubuntu:ubuntu' | chpasswd
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]