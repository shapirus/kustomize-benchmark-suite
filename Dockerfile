FROM alpine:3.18

RUN apk add --no-cache bash wget


### Set your versions to download/build and test here
# Release versions (to download) and commit hashes (to build) are allowed.
# Strings matching "<number>.<number>.<number>" are treated as downloadable releases,
# everything else is treated as git revision or tag.
#
# We have different lists for ARM and x86,
# because there were no linux/arm64 builds before v3.8.6, so they have to be tags to build locally.
#
ENV VERSIONS_ARM64="kustomize/v3.5.4 kustomize/v3.7.0 kustomize/v3.8.0 1c6481d0 00f0fd71 kustomize/v3.8.3 3.8.6 4.1.2 4.3.0 4.4.0 4.5.4 4.5.5 5.0.0 5.2.1"
ENV VERSIONS_X86_64="3.5.4 3.7.0 3.8.0 1c6481d0 00f0fd71 3.8.3 3.8.6 4.1.2 4.3.0 4.4.0 4.5.4 4.5.5 5.0.0 5.1.0 5.2.1"


WORKDIR /opt
SHELL ["/bin/bash", "-c"]

COPY tests/ tests/
COPY build.sh get-arch.sh /opt
RUN chmod a+x build.sh
RUN ./build.sh

COPY run-test.sh /opt
RUN chmod a+x run-test.sh

ENTRYPOINT [ "/bin/bash", "-c", "/opt/run-test.sh" ]
