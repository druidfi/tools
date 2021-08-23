FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -yqq build-essential curl && mkdir /tools
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt update && apt install -yqq nodejs
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update && apt install yarn
#RUN node --version && exit 1
#RUN npm --version && exit 1
#RUN yarn --version && exit 1

WORKDIR /tools
