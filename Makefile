TIMESTAMP := $(shell date -u +"%Y-%m-%d_%H%M%S")
DOCKER := $(shell { command -v podman || command -v docker; })

.PHONY: clean setup

all: setup build

build: firmware/$$(TIMESTAMP)-left.uf2 firmware/$$(TIMESTAMP)-right.uf2

clean:
	rm ./firmware/*.uf2

firmware/%-left.uf2 firmware/%-right.uf2: config/corne.keymap
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware \
		-v $(PWD)/config:/app/config:ro \
		-e TIMESTAMP=$(TIMESTAMP) \
		zmk-corne

setup: Dockerfile bin/build.sh config/west.yml
	$(DOCKER) build --tag zmk-corne --file Dockerfile .
