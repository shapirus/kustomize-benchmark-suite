FROM alpine:3.18

RUN apk add --no-cache bash wget


##
# Allowed values for the VERSIONS argument:
# - release versions matching "<number>.<number>.<number>": released binaries will be downloaded
# - any other string representing one of: commit hash, tag, branch,
#   pull release (format: "PR-<number>"): code from the corresponding git tree will be built
#
# Building pull releases requires GH_TOKEN build-arg to be set (can be a classic PAT with zero permissions)
#
# example:
#         docker build --build-arg VERSIONS="5.2.1 PR-5076 master" .
#         - or -
#         ./build-amd64 5.2.1 master
#         ./build-arm64 5.2.1 master
#         GH_TOKEN=ghp_xxxxx ./build-amd64 5.2.1 PR-5076 master
#
# versions to test can also be defined in the "versions-to-test" file, newline or space separated values.
##

ARG VERSIONS
ENV VERSIONS=${VERSIONS}

# required if you build PRs
ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN}
ENV GH_CLI_VERSION=2.37.0

WORKDIR /opt
SHELL ["/bin/bash", "-c"]

COPY tests/ tests/
COPY scripts/build-binaries.sh scripts/get-arch.sh /opt
RUN chmod a+x build-binaries.sh
RUN ./build-binaries.sh

COPY scripts/run-test.sh /opt
RUN chmod a+x run-test.sh

# reset the sensitive var
ENV GH_TOKEN=

ENTRYPOINT [ "/bin/bash", "-c", "/opt/run-test.sh" ]
