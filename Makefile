SHELL := /usr/bin/env bash
CWD := $(shell pwd)
PROJECT := $(shell basename "$(CWD)")

DEPENDENCIES := docker yq
$(foreach bin,$(DEPENDENCIES),\
    $(if $(shell command -v $(bin)),,\
        $(error $(bin) not found; install $(bin) and try again)))

ifeq ($(shell [ -t 0 ] && echo 1),1)
	DOCKER_DEFAULT_OPTIONS ?= -it --rm
else
	DOCKER_DEFAULT_OPTIONS ?= --rm
endif

USER_ID ?= $(shell id -u)
GROUP_ID ?= $(shell id -g)
ifeq ($(shell uname),Linux)
	DOCKER_USER := -u $(USER_ID):$(GROUP_ID)
else
	DOCKER_USER :=
endif

KICAD_CLI_IMAGE ?= ghcr.io/kicad/kicad:8.0
KICAD_CLI ?= docker run \
	$(DOCKER_DEFAULT_OPTIONS) \
	$(DOCKER_USER) \
	--volume "$(CWD)":"$(CWD)" \
	--workdir "$(CWD)" \
	$(KICAD_CLI_IMAGE) kicad-cli

.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%s\033[0m~%s\n", $$1, $$2}' \
	| column -s "~" -t

DRC_JSON_FILE ?= "$(CWD)/drc.json"
DRC_YAML_FILE ?= "$(CWD)/drc.yaml"
.PHONY: drc
drc: ## run the design rules checker
	@$(KICAD_CLI) pcb drc \
		--units mm \
		--schematic-parity \
		--format json \
		--output $(DRC_JSON_FILE) \
		"$(PROJECT).kicad_pcb"
	@yq e -P $(DRC_JSON_FILE) > $(DRC_YAML_FILE)
	@rm -f $(DRC_JSON_FILE)
