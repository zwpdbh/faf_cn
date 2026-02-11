# Makefile for Phoenix Development
# Project: faf_cn

.PHONY: help setup db.up db.down db.reset db.migrate db.seed server dev test format precommit \
        deps.get deps.update assets.setup assets.build clean kimi

# Default target
help:
	@echo "Available commands:"
	@echo "  make setup       - Initial project setup (deps, db, assets)"
	@echo "  make db.up       - Start PostgreSQL database (docker-compose)"
	@echo "  make db.down     - Stop PostgreSQL database"
	@echo "  make db.reset    - Reset database (drop, create, migrate, seed)"
	@echo "  make db.migrate  - Run database migrations"
	@echo "  make db.seed     - Seed the database"
	@echo "  make server      - Start Phoenix server with IEx (iex -S mix phx.server)"
	@echo "  make dev         - Alias for 'make server'"
	@echo "  make test        - Run tests"
	@echo "  make format      - Format code"
	@echo "  make precommit   - Run precommit checks (compile, format, test)"
	@echo "  make deps.get    - Get dependencies"
	@echo "  make deps.update - Update dependencies"
	@echo "  make assets.setup - Install and setup assets"
	@echo "  make assets.build - Build assets"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make kimi        - Start Kimi CLI with local MCP configuration"

# Setup and Installation
# ----------------------

setup: db.up
	@echo "Setting up project..."
	mix setup

deps.get:
	mix deps.get

deps.update:
	mix deps.update --all

# Database Commands
# -----------------

db.up:
	@echo "Starting PostgreSQL database..."
	docker-compose up -d db
	@echo "Waiting for database to be ready..."
	@sleep 2

db.down:
	@echo "Stopping PostgreSQL database..."
	docker-compose down

db.reset:
	mix ecto.reset

db.migrate:
	mix ecto.migrate

db.seed:
	mix run priv/repo/seeds.exs

# Development Server
# ------------------

server:
	iex -S mix phx.server

dev: server

# Asset Management
# ----------------

assets.setup:
	mix assets.setup

assets.build:
	mix assets.build

# Testing & Quality
# -----------------

test:
	mix test

format:
	mix format

precommit:
	mix precommit

# Cleanup
# -------

clean:
	mix clean
	rm -rf _build/

# Kimi CLI
# --------

kimi:
	kimi --mcp-config-file .kimi/mcp.json