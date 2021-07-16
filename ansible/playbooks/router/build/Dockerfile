FROM docker.io/golang:1.16.6-alpine

ARG VERSION

ENV CGO_ENABLED=0 \
    GOPATH=/go \
    GOBIN=/go/bin \
    GO111MODULE=on

WORKDIR /go/src/coredns

RUN \
  apk --no-cache --no-progress add ca-certificates git \
  && update-ca-certificates \
  && git clone https://github.com/coredns/coredns.git . \
  && git checkout ${VERSION} \
  && sed -i '/^kubernetes:kubernetes/a k8s_gateway:github.com/ori-edge/k8s_gateway' plugin.cfg \
  && go get github.com/ori-edge/k8s_gateway \
  && go generate \
  && go mod tidy \
  && GOOS=freebsd GOARCH=amd64 go build -ldflags "-s -w -X github.com/coredns/coredns/coremain.GitCommit=$(git describe --always)" -o coredns
