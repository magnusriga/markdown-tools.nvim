# Makefile

# Prevent targets from conflicting with files of the same name
.PHONY: test lint clean

# Default target (optional, runs if you just type 'make')
default: test

# Run the test suite
test:
	@echo "Running tests..."
	@./scripts/test

# Check Lua code style
lint:
	@echo "Checking code style with stylua..."
	@stylua --check .

# Remove temporary test dependencies
clean:
	@echo "Cleaning up test dependencies..."
	@rm -rf plenary.nvim