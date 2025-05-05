# Makefile

# Prevent targets from conflicting with files of the same name
.PHONY: test lint clean format pr

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

# Format Lua code style
format:
	@echo "Formatting code style with stylua..."
	@stylua .

# Remove temporary test dependencies
clean:
	@echo "Cleaning up test dependencies..."
	@rm -rf plenary.nvim

# Create a GitHub Pull Request from the current branch using the first commit for title/body.
# Assumes the current branch has been pushed to origin.
# Usage: make pr
pr:
	@echo "Creating Pull Request using GitHub CLI..."
	@gh pr create --fill