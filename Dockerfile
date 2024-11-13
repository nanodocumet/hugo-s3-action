FROM pahud/awscli-v2:node-lts

RUN yum update -y && \
    yum install -y curl jq && \
    npm install semver

RUN node -v && npm -v

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]