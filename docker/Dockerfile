FROM nvcr.io/nvidia/tensorrt:22.07-py3

ARG CUDA=11.3
ARG PYTHON_VERSION=3.8
ARG TORCH_VERSION=1.10.0
ARG TORCHVISION_VERSION=0.11.0
#ARG TORCHVISION_VERSION=0.13.0
#ARG ONNXRUNTIME_VERSION=1.8.1
ARG ONNXRUNTIME_VERSION=1.10.0
ARG MMCV_VERSION=1.5.3
ARG PPLCV_VERSION=0.7.0
ENV FORCE_CUDA="1"

ENV DEBIAN_FRONTEND=noninteractive

### change the system source for installing libs
ARG USE_SRC_INSIDE=false
RUN if [ ${USE_SRC_INSIDE} == true ] ; \
    then \
        sed -i s/archive.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list ; \
        sed -i s/security.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list ; \
        echo "Use aliyun source for installing libs" ; \
    else \
        echo "Keep the download source unchanged" ; \
    fi

### update apt and install libs
RUN sed -i s:/archive.ubuntu.com:/mirrors.tuna.tsinghua.edu.cn/ubuntu:g /etc/apt/sources.list
RUN cat /etc/apt/sources.list
RUN chmod 777 /tmp
RUN apt-get clean && apt-get update &&\
    apt-get install -y vim libsm6 libxext6 libxrender-dev libgl1-mesa-glx git wget zsh libssl-dev libopencv-dev libspdlog-dev --no-install-recommends &&\
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -v -o ~/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} conda-build pyyaml numpy ipython cython typing typing_extensions mkl mkl-include ninja && \
    /opt/conda/bin/conda clean -ya

### cudnn
COPY cudnn-local-repo-ubuntu2004-8.6.0.163_1.0-1_amd64.deb .
#RUN wget https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/11.8/cudnn-local-repo-ubuntu2004-8.6.0.163_1.0-1_amd64.deb && \
#     dpkg -i cudnn-local-repo-ubuntu2004-8.6.0.163_1.0-1_amd64.deb
RUN dpkg -i cudnn-local-repo-ubuntu2004-8.6.0.163_1.0-1_amd64.deb && \
    cp /var/cudnn-local-repo-ubuntu2004-8.6.0.163/cudnn-local-B0FE0A41-keyring.gpg /usr/share/keyrings/ && \
    dpkg -i /var/cudnn-local-repo-ubuntu2004-8.6.0.163/libcudnn8_8.6.0.163-1+cuda11.8_amd64.deb && \
    dpkg -i /var/cudnn-local-repo-ubuntu2004-8.6.0.163/libcudnn8-dev_8.6.0.163-1+cuda11.8_amd64.deb && \
    dpkg -i /var/cudnn-local-repo-ubuntu2004-8.6.0.163/libcudnn8-samples_8.6.0.163-1+cuda11.8_amd64.deb && \
    cp /usr/include/cudnn* /usr/local/cuda/include && chmod a+x /usr/local/cuda/include/cudnn*


### pytorch
RUN /opt/conda/bin/conda install pytorch==${TORCH_VERSION} torchvision==${TORCHVISION_VERSION} cudatoolkit=${CUDA} -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/linux-64/
ENV PATH /opt/conda/bin:$PATH

### install mmcv-full
#RUN /opt/conda/bin/pip install mmcv-full==${MMCV_VERSION} -f https://download.openmmlab.com/mmcv/dist/cu${CUDA//./}/torch${TORCH_VERSION}/index.html  -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN /opt/conda/bin/pip install mmcv-full==1.6.0 -f https://download.openmmlab.com/mmcv/dist/cu113/torch${TORCH_VERSION}/index.html  -i https://pypi.tuna.tsinghua.edu.cn/simple


WORKDIR /root/workspace
### get onnxruntime
RUN wget https://github.com/microsoft/onnxruntime/releases/download/v${ONNXRUNTIME_VERSION}/onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}.tgz \
    && tar -zxvf onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}.tgz &&\
    pip install onnxruntime-gpu==${ONNXRUNTIME_VERSION} -i https://pypi.tuna.tsinghua.edu.cn/simple
#COPY onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}.tgz .
#RUN tar -zxvf onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}.tgz &&\
#    pip install onnxruntime-gpu==${ONNXRUNTIME_VERSION} -i https://pypi.tuna.tsinghua.edu.cn/simple

### cp trt from pip to conda
#RUN cp -r /usr/local/lib/python${PYTHON_VERSION}/dist-packages/tensorrt* /opt/conda/lib/python${PYTHON_VERSION}/site-packages/

### install mmdeploy
ENV ONNXRUNTIME_DIR=/root/workspace/onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}
ENV TENSORRT_DIR=/workspace/tensorrt
ARG VERSION
RUN git clone https://github.com/HuangJunJie2017/mmdeploy.git
RUN cd mmdeploy &&\
    if [ -z ${VERSION} ] ; then echo "No MMDeploy version passed in, building on master" ; else git checkout tags/v${VERSION} -b tag_v${VERSION} ; fi &&\
    git submodule update --init --recursive &&\
    mkdir -p build &&\
    cd build &&\
    cmake -DMMDEPLOY_TARGET_BACKENDS="ort;trt" .. &&\
    make -j$(nproc) &&\
    cd .. &&\
    pip install -e .  -i https://pypi.tuna.tsinghua.edu.cn/simple

### build sdk
RUN git clone https://github.com/openppl-public/ppl.cv.git &&\
    cd ppl.cv &&\
    git checkout tags/v${PPLCV_VERSION} -b v${PPLCV_VERSION} &&\
    ./build.sh cuda

ENV BACKUP_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/compat/lib.real/:$LD_LIBRARY_PATH

RUN cd /root/workspace/mmdeploy &&\
    rm -rf build/CM* build/cmake-install.cmake build/Makefile build/csrc &&\
    mkdir -p build && cd build &&\
    cmake .. \
        -DMMDEPLOY_BUILD_SDK=ON \
        -DMMDEPLOY_BUILD_EXAMPLES=ON \
        -DCMAKE_CXX_COMPILER=g++ \
        -Dpplcv_DIR=/root/workspace/ppl.cv/cuda-build/install/lib/cmake/ppl \
        -DTENSORRT_DIR=${TENSORRT_DIR} \
        -DONNXRUNTIME_DIR=${ONNXRUNTIME_DIR} \
        -DMMDEPLOY_BUILD_SDK_PYTHON_API=ON \
        -DMMDEPLOY_TARGET_DEVICES="cuda;cpu" \
        -DMMDEPLOY_TARGET_BACKENDS="ort;trt" \
        -DMMDEPLOY_CODEBASES=all &&\
    make -j$(nproc) && make install &&\
    export SPDLOG_LEVEL=warn &&\
    if [ -z ${VERSION} ] ; then echo "Built MMDeploy master for GPU devices successfully!" ; else echo "Built MMDeploy version v${VERSION} for GPU devices successfully!" ; fi

ENV LD_LIBRARY_PATH="/root/workspace/mmdeploy/build/lib:${BACKUP_LD_LIBRARY_PATH}"

RUN pip install mmdet==2.25.1 mmsegmentation==0.25.0  -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    cd ..

RUN pip install pycuda \
    lyft_dataset_sdk \
    networkx==2.2 \
    numba==0.58.1 \
    numpy \
    nuscenes-devkit \
    plyfile \
    scikit-image \
    tensorboard \
    #trimesh==2.35.39 -i https://pypi.tuna.tsinghua.edu.cn/simple
    trimesh==4.4.1
    #numba==0.53.0 \
##########################################
ENV SHELL /usr/bin/zsh
RUN zsh
#set default shell to zsh
RUN chsh -s /bin/zsh

# oh-my-zsh install 
RUN sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# zsh-completions install
#RUN git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
RUN git clone https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions

# zsh-autosuggestions install
RUN git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# zsh-syntax-highlighting install
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

RUN sed -i "s/plugins=(git)/plugins=(git aliases copypath history zsh-completions zsh-autosuggestions zsh-syntax-highlighting)/g" /root/.zshrc

    ##########################################

########################################################
#ARG USERNAME=dev
#ARG USER_UID=1000
#ARG USER_GID=$USER_UID

# Create the user
#RUN groupadd --gid $USER_GID $USERNAME \
#    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
#    && apt-get update \
#    && apt-get install -y sudo \
#    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
#   && chmod 0440 /etc/sudoers.d/$USERNAME
# [Optional] Set the default user. Omit if you want to keep the default as root.
#USER $USERNAME
########################################################
