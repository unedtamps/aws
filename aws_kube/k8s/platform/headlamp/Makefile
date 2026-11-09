HELM ?= helm
KUBECTL ?= kubectl

RELEASE   ?= headlamp
NAMESPACE ?= headlamp
CHART     ?= .

HELM_ARGS     ?=
TEMPLATE_ARGS ?=
OUTPUT        ?= rendered.yaml

UNINSTALL_CONFIRM ?=

.PHONY: help deps require-deps lint template render check \
        install upgrade status port-forward uninstall clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make deps                    Download chart dependencies' \
		'  make lint                    Lint the chart' \
		'  make template                Render manifests to stdout' \
		'  make render                  Render manifests to $(OUTPUT)' \
		'  make check                   Lint and render (verification)' \
		'  make install                 helm upgrade --install' \
		'  make upgrade                 helm upgrade' \
		'  make status                  Helm status + Headlamp workloads' \
		'  make port-forward            Forward http://localhost:4466' \
		'  make uninstall               helm uninstall (UNINSTALL_CONFIRM=yes)' \
		'  make clean                   Remove charts/ and $(OUTPUT)' \
		'' \
		'Variables:' \
		'  HELM=helm                    Helm binary' \
		'  KUBECTL=kubectl              Kubectl binary' \
		'  RELEASE=headlamp             Release name' \
		'  NAMESPACE=headlamp           Release namespace' \
		'  HELM_ARGS="--wait"           Extra options for install/upgrade' \
		'  TEMPLATE_ARGS="--set x=y"    Extra options for template' \
		'  OUTPUT=rendered.yaml         Where make render writes' \
		'  UNINSTALL_CONFIRM=yes        Required for uninstall'

deps:
	$(HELM) dependency update $(CHART)

require-deps:
	@test -d charts || { \
		printf '%s\n' 'charts/ not found. Run: make deps'; \
		exit 1; \
	}

lint: require-deps
	$(HELM) lint $(CHART) $(HELM_ARGS)

template: require-deps
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS)

render: require-deps
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS) > $(OUTPUT)
	@printf 'Wrote %s\n' $(OUTPUT)

check: lint
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS) > /dev/null
	@printf 'OK: chart lints and renders cleanly\n'

install: require-deps
	$(HELM) upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace $(HELM_ARGS)

upgrade: require-deps
	$(HELM) upgrade $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace $(HELM_ARGS)

status:
	$(HELM) status $(RELEASE) -n $(NAMESPACE)
	@$(KUBECTL) -n $(NAMESPACE) get deploy,pod,svc

port-forward:
	$(KUBECTL) -n $(NAMESPACE) port-forward svc/$(RELEASE) 4466:80

uninstall: require-deps
	@test "$(UNINSTALL_CONFIRM)" = "yes" || { \
		printf '%s\n' 'This removes the Headlamp release.'; \
		printf '%s\n' 'The namespace and its service account are NOT removed.'; \
		printf '%s\n' 'Use: make uninstall UNINSTALL_CONFIRM=yes'; \
		exit 1; \
	}
	$(HELM) uninstall $(RELEASE) -n $(NAMESPACE)

clean:
	rm -rf charts
	rm -f $(OUTPUT)
