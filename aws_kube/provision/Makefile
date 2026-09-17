TOFU ?= tofu
AWS_PROFILE ?= dev

PLAN_DIR ?= plan
PLAN_NAME ?=

# Support both `make plan test.tfplan` and `make plan PLAN_NAME=test`.
PLAN_TARGETS := plan plan-destroy destroy-plan apply destroy show show-destroy
PLAN_ARGUMENT := $(word 2,$(MAKECMDGOALS))
ifneq ($(filter $(PLAN_TARGETS),$(MAKECMDGOALS)),)
ifneq ($(strip $(PLAN_ARGUMENT)),)
override PLAN_NAME := $(PLAN_ARGUMENT)
.PHONY: $(PLAN_ARGUMENT)
$(PLAN_ARGUMENT):
	@:
endif
endif

plan_filename = $(if $(filter %.tfplan,$(1)),$(notdir $(1)),$(notdir $(1)).tfplan)
PLAN_FILE ?= $(PLAN_DIR)/$(call plan_filename,$(PLAN_NAME))
DESTROY_PLAN_DIR ?= $(PLAN_DIR)/destroy
DESTROY_PLAN_FILE ?= $(DESTROY_PLAN_DIR)/$(call plan_filename,$(PLAN_NAME))
DESTROY_CONFIRM ?=

# Pass extra OpenTofu options, for example:
# make plan PLAN_NAME=dev TOFU_ARGS='-var-file=staging.tfvars'
TOFU_ARGS ?=
TOFU_INIT_ARGS ?= -input=false -no-color
TOFU_PLAN_ARGS ?= -input=false -no-color
TOFU_APPLY_ARGS ?= -input=false -no-color

.PHONY: help init fmt fmt-check validate plan plan-destroy destroy-plan apply destroy show show-destroy output state-list clean require-plan require-destroy-confirmation

help:
	@printf '%s\n' \
		'Usage:' \
		'  make plan <name>[.tfplan]                        Create plan/<name>.tfplan' \
		'  make apply <name>[.tfplan]                       Apply plan/<name>.tfplan' \
		'  make show <name>[.tfplan]                        Show a saved plan' \
		'  make plan-destroy <name>[.tfplan]                Create plan/destroy/<name>.tfplan' \
		'  make destroy <name>[.tfplan]                     Apply a saved destroy plan' \
		'  make show-destroy <name>[.tfplan]                Show a saved destroy plan' \
		'  make init                                        Initialize OpenTofu' \
		'  make fmt                                         Format all configurations' \
		'  make fmt-check                                   Check formatting' \
		'  make validate                                    Validate configuration' \
		'  make output                                      Show state outputs' \
		'  make state-list                                  List resources in state' \
		'  make clean                                       Remove generated plan files' \
		'' \
		'Variables:' \
		'  AWS_PROFILE=dev                                  AWS profile to use' \
		'  PLAN_DIR=plan                                    Directory for saved plans' \
		'  PLAN_NAME=<name>                                 Alternative plan name syntax' \
		'  DESTROY_CONFIRM=yes                              Required for destroy' \
		'  TOFU_ARGS="..."                                  Extra options for plan'

init:
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) init $(TOFU_INIT_ARGS)

fmt:
	$(TOFU) fmt -recursive

fmt-check:
	$(TOFU) fmt -recursive -check -diff

validate: init
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) validate -no-color

require-plan:
	@test -n "$(PLAN_NAME)" || { \
		printf '%s\n' 'Plan name is required. Example: make plan dev'; \
		exit 1; \
	}

plan: require-plan init validate
	@mkdir -p "$(dir $(PLAN_FILE))"
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) plan $(TOFU_PLAN_ARGS) $(TOFU_ARGS) -out="$(PLAN_FILE)"
	@printf 'Saved plan: %s\n' "$(PLAN_FILE)"

plan-destroy: require-plan init validate
	@mkdir -p "$(dir $(DESTROY_PLAN_FILE))"
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) plan $(TOFU_PLAN_ARGS) $(TOFU_ARGS) -destroy -out="$(DESTROY_PLAN_FILE)"
	@printf 'Saved destroy plan: %s\n' "$(DESTROY_PLAN_FILE)"

destroy-plan: plan-destroy

apply: require-plan init
	@test -f "$(PLAN_FILE)" || { \
		printf 'Plan file not found: %s\n' "$(PLAN_FILE)"; \
		printf 'Create it first with: make plan %s\n' "$(PLAN_NAME)"; \
		exit 1; \
	}
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) apply $(TOFU_APPLY_ARGS) "$(PLAN_FILE)"

require-destroy-confirmation:
	@test "$(DESTROY_CONFIRM)" = "yes" || { \
		printf '%s\n' 'Destroy requires explicit confirmation.'; \
		printf 'Use: make destroy %s DESTROY_CONFIRM=yes\n' "$(PLAN_NAME)"; \
		exit 1; \
	}

destroy: require-plan require-destroy-confirmation init
	@test -f "$(DESTROY_PLAN_FILE)" || { \
		printf 'Destroy plan file not found: %s\n' "$(DESTROY_PLAN_FILE)"; \
		printf 'Create it first with: make plan-destroy %s\n' "$(PLAN_NAME)"; \
		exit 1; \
	}
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) apply $(TOFU_APPLY_ARGS) "$(DESTROY_PLAN_FILE)"

show: require-plan
	@test -f "$(PLAN_FILE)" || { \
		printf 'Plan file not found: %s\n' "$(PLAN_FILE)"; \
		exit 1; \
	}
	$(TOFU) show -no-color "$(PLAN_FILE)"

show-destroy: require-plan
	@test -f "$(DESTROY_PLAN_FILE)" || { \
		printf 'Destroy plan file not found: %s\n' "$(DESTROY_PLAN_FILE)"; \
		exit 1; \
	}
	$(TOFU) show -no-color "$(DESTROY_PLAN_FILE)"

output: init
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) output

state-list: init
	AWS_PROFILE="$(AWS_PROFILE)" $(TOFU) state list

clean:
	rm -rf "$(PLAN_DIR)"
