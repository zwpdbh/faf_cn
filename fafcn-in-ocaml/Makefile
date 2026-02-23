# FAF CN OCaml/Melange Makefile
# Wraps npm scripts for convenience

.PHONY: all build watch serve clean deps help

# Default target
all: build

# Install dependencies
deps:
	npm run install:npm-opam

# Build the frontend
build:
	npm run build

# Watch mode for development
watch:
	npm run watch

# Serve the application with Vite
serve:
	npm run serve

# Clean build artifacts
clean:
	npm run clean

# Build for production
release:
	npm run bundle

# Format code
fmt:
	npm run fmt

# Check formatting
fmt-check:
	npm run fmt:check

# Help target
help:
	@echo "FAF CN OCaml/Melange Project"
	@echo ""
	@echo "Available targets:"
	@echo "  make deps      - Install dependencies (npm + opam)"
	@echo "  make build     - Build the frontend"
	@echo "  make watch     - Watch mode for development"
	@echo "  make serve     - Serve with Vite dev server"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make release   - Build for production"
	@echo "  make fmt       - Format code"
	@echo "  make fmt-check - Check code formatting"
	@echo ""
	@echo "Or use npm directly:"
	@echo "  npm run watch  - Watch and rebuild"
	@echo "  npm run serve  - Start dev server"
