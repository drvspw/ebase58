BASEDIR = $(shell pwd)
APPNAME = $(shell basename $(BASEDIR))
REBAR = rebar3

LINTERS = lint xref eunit

compile: ## compile
	$(REBAR) compile

eunit: ## run eunit tests
	$(REBAR) eunit

xref: ## xref analysis
	$(REBAR) xref

dialyzer: ## dialyzer
	$(REBAR) dialyzer

check-deps: ## check dependencies
	$(REBAR) check-deps

lint: ## lint
	$(REBAR) lint

test: $(LINTERS) ## run eunit test suites

console: test ## launch a shell
	$(REBAR) shell

clean: ## clean
	$(REBAR) clean
	rm -rf _build

test-coverage-report: ## generate test coverage report
	$(REBAR) cover --verbose

help: ## Display help information
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
