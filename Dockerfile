FROM centos:7
LABEL maintainer="vasu1124@actvirtual.com"

COPY /helloworld /
CMD ["/helloworld"]
