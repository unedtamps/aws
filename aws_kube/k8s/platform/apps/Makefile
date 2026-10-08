HELM ?= helm
KUBECTL ?= kubectl

RELEASE   ?= platform-apps
NAMESPACE ?= argocd
CHART     ?= .

LBC_NAMESPACE ?= kube-system
LBC_WEBHOOK_SERVICE ?= aws-load-balancer-webhook-service

HELM_ARGS     ?=
TEMPLATE_ARGS ?=
OUTPUT        ?= rendered.yaml

UNINSTALL_CONFIRM ?=

.PHONY: help precheck lint template render check \
        install upgrade status uninstall clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make lint                 Lint the chart' \
		'  make template             Render manifests to stdout' \
		'  make render               Render manifests to $(OUTPUT)' \
		'  make check                Lint and render (verification)' \
		'  make precheck             Verify cluster has the CRDs and webhook' \
		'  make install              helm upgrade --install' \
		'  make upgrade              helm upgrade' \
		'  make status               helm status + Application sync status' \
		'  make uninstall            helm uninstall (UNINSTALL_CONFIRM=yes)' \
		'  make clean                Remove $(OUTPUT)' \
		'' \
		'URUTAN WAJIB:' \
		'  Dua chart, dua perintah. Chart ini membuat resource yang memakai' \
		'  CRD dari ../core, jadi core harus lebih dulu:' \
		'    make -C ../core install' \
		'  Lalu chart ini:' \
		'    make install' \
		'' \
		'  Resources here also need the AWS Load Balancer Controller' \
		'  webhook to have endpoints before a TargetGroupBinding can be' \
		'  created. make precheck reports that clearly.' \
		'' \
		'Variables:' \
		'  HELM=helm                          Helm binary' \
		'  KUBECTL=kubectl                    Kubectl binary' \
		'  RELEASE=platform-apps              Release name' \
		'  NAMESPACE=argocd                   Where Applications are created' \
		'  LBC_NAMESPACE=$(LBC_NAMESPACE) Where LBC runs' \
		'  HELM_ARGS="--wait"                 Extra options for install' \
		'  TEMPLATE_ARGS="--set x=y"          Extra options for template' \
		'  OUTPUT=rendered.yaml               Where make render writes' \
		'  UNINSTALL_CONFIRM=yes              Required for uninstall'

# Verify both CRDs this chart creates, plus the LBC webhook endpoints that a
# TargetGroupBinding needs at creation time. The webhook check is what turns
# "no endpoints available for service" into an actionable message.
precheck:
	@missing=0; \
	for crd in applications.argoproj.io targetgroupbindings.elbv2.k8s.aws; do \
		if ! $(KUBECTL) get crd "$$crd" >/dev/null 2>&1; then \
			printf '%s\n' "CRD $$crd belum ada di cluster ini."; \
			missing=1; \
		fi; \
	done; \
	if [ $$missing -ne 0 ]; then \
		printf '%s\n' ''; \
		printf '%s\n' 'Install chart core dulu:'; \
		printf '%s\n' '  make -C ../core install'; \
		exit 1; \
	fi; \
	if ! $(KUBECTL) get endpoints "$(LBC_WEBHOOK_SERVICE)" -n "$(LBC_NAMESPACE)" \
		-o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | grep -q .; then \
		printf '%s\n' 'LBC webhook belum punya endpoint di namespace $(LBC_NAMESPACE).'; \
		printf '%s\n' 'TargetGroupBinding akan gagal dibuat dengan:'; \
		printf '%s\n' '  no endpoints available for service "$(LBC_WEBHOOK_SERVICE)"'; \
		printf '%s\n' ''; \
		printf '%s\n' 'Tunggu pod LBC ready lalu ulangi:'; \
		printf '%s\n' '  make -C ../core wait'; \
		exit 1; \
	fi; \
	printf '%s\n' 'OK: CRD tersedia, LBC webhook siap'

lint:
	$(HELM) lint $(CHART) $(HELM_ARGS)

template:
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS)

render:
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS) > $(OUTPUT)
	@printf 'Wrote %s\n' $(OUTPUT)

check: lint
	$(HELM) template $(RELEASE) $(CHART) -n $(NAMESPACE) $(TEMPLATE_ARGS) > /dev/null
	@printf 'OK: chart lints and renders cleanly\n'

install: precheck
	$(HELM) upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) $(HELM_ARGS)

upgrade: precheck
	$(HELM) upgrade $(RELEASE) $(CHART) -n $(NAMESPACE) $(HELM_ARGS)

status:
	@$(HELM) status $(RELEASE) -n $(NAMESPACE) 2>/dev/null \
		|| printf '%s\n' 'Release not installed.'
	@$(KUBECTL) get applications.argoproj.io -n $(NAMESPACE) -o wide 2>/dev/null \
		|| printf '%s\n' 'No Application found.'
	@$(KUBECTL) get targetgroupbinding -A 2>/dev/null || true

uninstall:
	@test "$(UNINSTALL_CONFIRM)" = "yes" || { \
		printf '%s\n' 'Deletes every Argo CD Application and TargetGroupBinding'; \
		printf '%s\n' 'in this release.'; \
		printf '%s\n' ''; \
		printf '%s\n' 'Deleting an Application triggers prune, so the workloads'; \
		printf '%s\n' 'it manages will also be removed from the cluster.'; \
		printf '%s\n' ''; \
		printf '%s\n' 'Use: make uninstall UNINSTALL_CONFIRM=yes'; \
		exit 1; \
	}
	$(HELM) uninstall $(RELEASE) -n $(NAMESPACE)

clean:
	rm -f $(OUTPUT)