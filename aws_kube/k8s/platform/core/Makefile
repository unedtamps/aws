HELM ?= helm
KUBECTL ?= kubectl

RELEASE   ?= platform
NAMESPACE ?= kube-system
CHART     ?= .

HELM_ARGS     ?=
TEMPLATE_ARGS ?=
OUTPUT        ?= rendered.yaml

WAIT_TIMEOUT  ?= 300
WAIT_INTERVAL ?= 5

UNINSTALL_CONFIRM ?=

.PHONY: help deps require-deps lint template render check status wait \
        install upgrade helm-status uninstall clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make deps                    Download chart dependencies' \
		'  make lint                    Lint the chart' \
		'  make template                Render manifests to stdout' \
		'  make render                  Render manifests to $(OUTPUT)' \
		'  make check                   Lint and render (verification)' \
		'  make status                  Show all workloads across namespaces' \
		'  make wait                    Block until all workloads are ready' \
		'  make install                 helm upgrade --install' \
		'  make upgrade                 helm upgrade' \
		'  make helm-status             helm status for this release' \
		'  make uninstall               helm uninstall (UNINSTALL_CONFIRM=yes)' \
		'  make clean                   Remove charts/ and $(OUTPUT)' \
		'' \
		'This chart installs the controllers only:' \
		'  aws-load-balancer-controller, external-secrets, argo-cd, traefik' \
		'' \
		'Argo CD Applications and the TargetGroupBinding are NOT here. They' \
		'live in ../apps and must be installed after this release:' \
		'  make -C ../apps install' \
		'' \
		'Variables:' \
		'  HELM=helm                    Helm binary' \
		'  KUBECTL=kubectl              Kubectl binary' \
		'  RELEASE=platform             Release name' \
		'  NAMESPACE=kube-system        Release namespace' \
		'  HELM_ARGS="--strict"         Extra options for lint and install' \
		'  TEMPLATE_ARGS="--set x=y"    Extra options for template' \
		'  OUTPUT=rendered.yaml         Where make render writes' \
		'  WAIT_TIMEOUT=$(WAIT_TIMEOUT)  Seconds before wait gives up' \
		'  WAIT_INTERVAL=$(WAIT_INTERVAL) Seconds between readiness polls' \
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

status:
	@$(KUBECTL) get deploy,statefulset -A

# Poll until every Deployment and StatefulSet reports all replicas ready.
# Times out instead of failing fast so a stuck component is visible rather
# than hidden behind an aborted install.
wait:
	@started=$$(date +%s); \
	while :; do \
		pending=$$($(KUBECTL) get deploy,statefulset -A \
			-o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,READY:.status.readyReplicas,WANT:.spec.replicas' \
			--no-headers 2>/dev/null \
			| awk '$$3+0 < $$4+0 { printf "  %s/%s  %d/%d\n", $$1, $$2, $$3+0, $$4+0 }'); \
		elapsed=$$(( $$(date +%s) - $$started )); \
		if [ -z "$$pending" ]; then \
			printf '[%ss] semua workload ready\n' "$$elapsed"; \
			exit 0; \
		fi; \
		if [ $$elapsed -ge $(WAIT_TIMEOUT) ]; then \
			printf '\nTimeout setelah %ss. Masih belum ready:\n%s\n' "$(WAIT_TIMEOUT)" "$$pending"; \
			exit 1; \
		fi; \
		printf '[%ss] belum ready:\n%s\n' "$$elapsed" "$$pending"; \
		sleep $(WAIT_INTERVAL); \
	done

install: require-deps
	$(HELM) upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) $(HELM_ARGS)

upgrade: require-deps
	$(HELM) upgrade $(RELEASE) $(CHART) -n $(NAMESPACE) $(HELM_ARGS)

helm-status:
	$(HELM) status $(RELEASE) -n $(NAMESPACE)

uninstall: require-deps
	@test "$(UNINSTALL_CONFIRM)" = "yes" || { \
		printf '%s\n' 'This removes the platform release.'; \
		printf '%s\n' ''; \
		printf '%s\n' 'Namespaces argocd, traefik, external-secrets are created'; \
		printf '%s\n' 'manually and are NOT removed. Remove them manually:'; \
		printf '%s\n' '  kubectl delete namespace argocd traefik external-secrets'; \
		printf '%s\n' ''; \
		printf '%s\n' 'Use: make uninstall UNINSTALL_CONFIRM=yes'; \
		exit 1; \
	}
	$(HELM) uninstall $(RELEASE) -n $(NAMESPACE)

clean:
	rm -rf charts
	rm -f $(OUTPUT)