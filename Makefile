.PHONY: test test-all test-verbose clean install-luaunit help lint

# Default target
help:
	@echo "Available targets:"
	@echo "  test            - Run all tests with nvim --headless"
	@echo "  clean           - Clean test cache files"

# Run tests with nvim headless
test:
	@echo "Running tests with nvim --headless..."
	@nvim --headless -u NONE \
		-c "lua package.path = 'lua/?.lua;test/?.lua;' .. package.path" \
		-c "lua dofile('test/run.lua')" \
		-c "qa!"

# Clean generated files
clean:
	@echo "Cleaning up..."
	@rm -rf test/*.lua~
	@rm -rf test/*.out
	@rm -rf *.swp
	@rm -rf /tmp/nvim-plug_test_* 2>/dev/null || true
