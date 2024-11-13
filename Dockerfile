FROM pahud/awscli-v2:node-lts

RUN yum update -y && \
    yum install -y curl jq && \
    yum install -y https://extras.getpagespeed.com/release-latest.rpm

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]