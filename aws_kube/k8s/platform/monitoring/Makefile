HELM ?= helm
KUBECTL ?= kubectl

RELEASE   ?= monitoring
NAMESPACE ?= monitoring
CHART     ?= .

HELM_ARGS     ?=
TEMPLATE_ARGS ?=
OUTPUT        ?= rendered.yaml

SKIP_CRDS         ?=
UNINSTALL_CONFIRM ?=

.PHONY: help deps require-deps crds lint template render check \
        install upgrade status uninstall clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make deps                    Download chart dependencies' \
		'  make crds                    Apply CRDs from the vendored chart' \
		'  make lint                    Lint the chart' \
		'  make template                Render manifests to stdout' \
		'  make render                  Render manifests to $(OUTPUT)' \
		'  make check                   Lint and render (verification)' \
		'  make install                 Apply CRDs, then helm upgrade --install' \
		'  make upgrade                 Apply CRDs, then helm upgrade' \
		'  make status                  Helm status + monitoring workloads' \
		'  make uninstall               helm uninstall (UNINSTALL_CONFIRM=yes)' \
		'  make clean                   Remove charts/ and $(OUTPUT)' \
		'' \
		'Access (port-forward):' \
		'  Grafana:      svc/monitoring-grafana 3000:80' \
		'  Prometheus:   svc/monitoring-kube-prometheus-prometheus 9090:9090' \
		'  Alertmanager: svc/monitoring-kube-prometheus-alertmanager 9093:9093' \
		'' \
		'Grafana admin password:' \
		'  kubectl -n $(NAMESPACE) get secret grafana-admin -o jsonpath=\"{.data.admin-password}\" | base64 -d' \
		'' \
		'Variables:' \
		'  HELM=helm                    Helm binary' \
		'  KUBECTL=kubectl              Kubectl binary' \
		'  RELEASE=monitoring           Release name' \
		'  NAMESPACE=monitoring         Release namespace' \
		'  HELM_ARGS="--wait"           Extra options for install/upgrade' \
		'  TEMPLATE_ARGS="--set x=y"    Extra options for template' \
		'  OUTPUT=rendered.yaml         Where make render writes' \
		'  SKIP_CRDS=1                  Skip CRD apply in install/upgrade' \
		'  UNINSTALL_CONFIRM=yes        Required for uninstall'

deps:
	$(HELM) dependency update $(CHART)

require-deps:
	@test -d charts || { \
		printf '%s\n' 'charts/ not found. Run: make deps'; \
		exit 1; \
	}

# Helm only installs CRDs on a first install and never on upgrade. Apply them
# explicitly so upgrades pick up new CRDs too. The awk pass inserts document
# separators because some vendored charts concatenate CRDs without them.
crds: require-deps
	@if [ "$(SKIP_CRDS)" = "1" ]; then \
		printf '%s\n' 'SKIP_CRDS=1: skipping CRD apply'; \
		exit 0; \
	fi; \
	$(HELM) show crds $(CHART) \
		| awk '/^apiVersion: apiextensions.k8s.io\// { print "---" } { print }' \
		| $(KUBECTL) apply --server-side --force-conflicts -f -

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
	@$(MAKE) --no-print-directory crds
	$(HELM) upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace $(HELM_ARGS)

upgrade: require-deps
	@$(MAKE) --no-print-directory crds
	$(HELM) upgrade $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace $(HELM_ARGS)

status:
	$(HELM) status $(RELEASE) -n $(NAMESPACE)
	@$(KUBECTL) -n $(NAMESPACE) get deploy,statefulset,pod,svc

uninstall: require-deps
	@test "$(UNINSTALL_CONFIRM)" = "yes" || { \
		printf '%s\n' 'This removes the monitoring release.'; \
		printf '%s\n' ''; \
		printf '%s\n' 'CRDs and the namespace are NOT removed.'; \
		printf '%s\n' 'Use: make uninstall UNINSTALL_CONFIRM=yes'; \
		exit 1; \
	}
	$(HELM) uninstall $(RELEASE) -n $(NAMESPACE)

clean:
	rm -rf charts
	rm -f $(OUTPUT)
