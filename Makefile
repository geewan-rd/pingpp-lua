.PHONY: local lint build

local: build
	luarocks make --local pingpp-lua-dev-1.rockspec

build: 
	moonc payments lint_config.moon

lint:
	moonc -l payments
