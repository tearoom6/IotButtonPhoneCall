FROM amazonlinux:latest

ENV RBENV_ROOT=/opt/rbenv
ENV PATH $RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH

RUN yum install -y git bzip2 tar make gcc openssl-devel readline-devel zlib-devel && \
    git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT && \
    mkdir $RBENV_ROOT/plugins && \
    git clone https://github.com/rbenv/ruby-build.git $RBENV_ROOT/plugins/ruby-build && \
    rbenv install 2.5.3 && \
    rbenv global 2.5.3 && \
    gem install bundler && \
    gem update --system && \
    rbenv rehash

