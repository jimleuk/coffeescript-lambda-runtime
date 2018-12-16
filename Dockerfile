FROM lambci/lambda-base:build

COPY bootstrap bootstrap.coffee babel.config.js /opt/
COPY node_modules /opt/node_modules/

ARG NODE_VERSION

RUN curl -sSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | \
  tar -xJ -C /opt --strip-components 1 -- node-v${NODE_VERSION}-linux-x64/bin/node && \
  strip /opt/bin/node

RUN cd /opt && \
  zip -yr /tmp/node-v${NODE_VERSION}.zip ./*