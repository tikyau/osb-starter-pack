IMAGE_NAME ?= quay.io/osb-starter-pack/servicebroker

# If the USE_SUDO_FOR_DOCKER env var is set, prefix docker commands with 'sudo'
ifdef USE_SUDO_FOR_DOCKER
	SUDO_CMD = sudo
endif

build:
	go build -i github.com/pmorie/osb-starter-pack/cmd/servicebroker

test:
	go test -v $(shell go list ./... | grep -v /vendor/ | grep -v /test/)

linux:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
	go build --ldflags="-s" github.com/pmorie/osb-starter-pack/cmd/servicebroker

image: linux
	cp servicebroker image/
	$(SUDO_CMD) docker build image/ -t $(IMAGE_NAME)

clean:
	rm -f servicebroker

push: image
	$(SUDO_CMD) docker push $(IMAGE_NAME):latest

deploy-helm: image
	helm install charts/servicebroker \
	--name broker-skeleton --namespace broker-skeleton \
	--set imagePullPolicy=Never,image=$(IMAGE_NAME):latest

deploy-openshift: image
	oc new-project osb-starter-pack
	oc process -f openshift/starter-pack.yaml -p IMAGE=$(IMAGE_NAME):latest | oc create -f -
