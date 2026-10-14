FROM alpine:latest
LABEL maintainer="vasu1124@actvirtual.com"

# Build the sample on demand instead of shipping a stale binary.
# Requires: make + golang on the build host, or: make -C ../../..
# The resulting /helloworld is a fully static ELF for the target arch.
COPY /helloworld /
CMD ["/helloworld"]
