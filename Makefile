# Build helloworld on demand (never committed as a binary).
#
# Defaults to linux/arm64 ELF (matches the container101 VM + Docker on ARM,
# and is what the Docker-based exercises in 08/09 consume).
# Override with:
#   make GOOS=linux GOARCH=amd64   # linux x86-64
#   make GOOS=darwin GOARCH=arm64  # native macOS
GOCMD := CGO_ENABLED=0 go build -trimpath
GOOS  ?= linux
GOARCH ?= arm64

.PHONY: all clean
all: helloworld

helloworld: helloworld.go
	$(GOCMD) -o helloworld $<

# Build for the local host (native OS/arch) for the strace exercise in 09.
host: helloworld.go
	$(GOCMD) -o helloworld $<

clean:
	rm -f helloworld helloworld-amd64 helloworld-arm64
