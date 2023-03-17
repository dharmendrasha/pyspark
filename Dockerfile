FROM openjdk:11.0.14-jre-slim-buster as builder

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater
ENV SPARK_VERSION=3.2.1 \
    HADOOP_VERSION=3.2 \
    SPARK_HOME=/opt/spark \
    PYTHONHASHSEED=1

# Add Dependencies for PySpark
RUN apt-get update \
    && apt-get install -y \
    curl \
    vim \
    wget \
    software-properties-common \
    ssh \
    net-tools \
    ca-certificates \
    python3 \
    python3-pip \
    python3-numpy \
    python3-matplotlib \
    python3-scipy \
    python3-pandas \
    python3-simpy

RUN update-alternatives --install "/usr/bin/python" "python" "$(which python3)" 10

RUN pip3 install pyspark==${SPARK_VERSION}

RUN echo alias python=python3 >> ~/.bashrc
RUN echo alias pip=pip3 >> ~/.bashrc

RUN echo alias python=python3 >> ~/.bash_aliases
RUN echo alias pip=pip3 >> ~/.bash_aliases

# RUN source ~/.bashrc
# RUN source ~/.bash_aliases



RUN wget --no-verbose -O apache-spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
    && mkdir -p /opt/spark \
    && tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 \
    && rm apache-spark.tgz


FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_PORT=7077 \
    SPARK_MASTER_WEBUI_PORT=8080 \
    SPARK_LOG_DIR=/opt/spark/logs \
    SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
    SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out \
    SPARK_WORKER_WEBUI_PORT=8080 \
    SPARK_WORKER_PORT=7000 \
    SPARK_MASTER="spark://spark-master:7077" \
    SPARK_WORKLOAD="master"

EXPOSE 8080 7077 7000

RUN mkdir -p $SPARK_LOG_DIR && \
    touch $SPARK_MASTER_LOG && \
    touch $SPARK_WORKER_LOG && \
    ln -sf /dev/stdout $SPARK_MASTER_LOG && \
    ln -sf /dev/stdout $SPARK_WORKER_LOG

COPY start-spark.sh /

SHELL [ "/bin/bash" ]

CMD ["/bin/bash", "/start-spark.sh"]