FROM docker.io/golang:1.17.5-alpine

ARG VERSION
ENV VERSION=${VERSION:-v1.8.6}

ENV CGO_ENABLED=0 \
    GOPATH=/go \
    GOBIN=/go/bin \
    GO111MODULE=on

WORKDIR /go/src/coredns

RUN \
  apk --no-cache --no-progress add ca-certificates git

RUN update-ca-certificates

RUN \
  git clone https://github.com/coredns/coredns.git --branch "${VERSION}" --depth 1 --single-branch . \
  && sed -i '/^kubernetes:kubernetes/a k8s_gateway:github.com/ori-edge/k8s_gateway' plugin.cfg

RUN \
  go get github.com/ori-edge/k8s_gateway \
  && go generate \
  && go mod tidy

ENV GOOS=freebsd \
    GOARCH=amd64

RUN \
  go build -ldflags "-s -w -X github.com/coredns/coredns/coremain.GitCommit=$(git describe --always)" -o coredns
