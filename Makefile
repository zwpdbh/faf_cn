# Makefile for Phoenix Development
# Project: faf_cn

.PHONY: help setup db.up db.down db.reset db.migrate db.seed server dev test format precommit \
        deps.get deps.update assets.setup assets.build clean kimi \
        check quality dialyzer dialyzer.setup credo test.full test.run \
        fly.deploy fly.status fly.logs fly.console fly.db.connect fly.open fly.config \
        fly.secrets fly.secrets.set fly.build fly.apps.create

# Default target
help:
	@echo "Available commands:"
	@echo ""
	@echo "Setup & Development:"
	@echo "  make setup          - Initial project setup (deps, db, assets)"
	@echo "  make server         - Start Phoenix server with IEx (iex -S mix phx.server)"
	@echo "  make dev            - Alias for 'make server'"
	@echo ""
	@echo "Database (Local):"
	@echo "  make db.up          - Start PostgreSQL database (docker-compose)"
	@echo "  make db.down        - Stop PostgreSQL database"
	@echo "  make db.reset       - Reset database (drop, create, migrate, seed)"
	@echo "  make db.migrate     - Run database migrations"
	@echo "  make db.seed        - Seed the database"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  make test           - Run tests + credo (fast)"
	@echo "  make test.full      - Run tests + credo + dialyzer (slow)"
	@echo "  make format         - Format code"
	@echo "  make precommit      - Run full precommit suite"
	@echo "  make check          - Run all quality checks (format, dialyzer, credo)"
	@echo "  make quality        - Same as check"
	@echo ""
	@echo "Fly.io Deployment:"
	@echo "  make fly.deploy     - Deploy application to Fly.io"
	@echo "  make fly.build      - Build Docker image without deploying"
	@echo "  make fly.status     - Check application status on Fly.io"
	@echo "  make fly.logs       - View application logs on Fly.io"
	@echo "  make fly.console    - Open remote IEx console on Fly.io"
	@echo "  make fly.db.connect - Connect to production database"
	@echo "  make fly.open       - Open application in browser"
	@echo "  make fly.config     - Show Fly.io configuration"
	@echo "  make fly.secrets    - List all secrets on Fly.io"
	@echo "  make fly.secrets.set KEY=val - Set a secret on Fly.io"
	@echo ""
	@echo "Dependencies & Assets:"
	@echo "  make deps.get       - Get Elixir dependencies"
	@echo "  make deps.update    - Update Elixir dependencies"
	@echo "  make assets.setup   - Install and setup assets"
	@echo "  make assets.build   - Build assets"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make kimi           - Start Kimi CLI with local MCP configuration"

# Setup and Installation
# ----------------------

setup: db.up
	@echo "Setting up project..."
	mix setup

deps.get:
	mix deps.get

deps.update:
	mix deps.update --all

# Database Commands (Local)
# -------------------------

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

test: test.run credo
	@echo "✅ Tests and Credo passed (run 'make dialyzer' separately)"

test.full: test.run credo dialyzer
	@echo "✅ Full test suite passed (including Dialyzer)"

test.run:
	mix test

format:
	mix format

check: format.check dialyzer credo
	@echo "✅ All quality checks passed"

quality: check

precommit:
	mix precommit

format.check:
	mix format --check-formatted

# Static Analysis
# ---------------

dialyzer:
	mix dialyzer.check

dialyzer.setup:
	mix dialyzer.setup

credo:
	mix credo --strict

# Fly.io Deployment
# -----------------

# Deploy the application to Fly.io
fly.deploy:
	@echo "🚀 Deploying to Fly.io..."
	fly deploy

# Build Docker image without deploying
fly.build:
	@echo "🔨 Building Docker image..."
	fly deploy --build-only

# Check application status
fly.status:
	@echo "📊 Checking Fly.io status..."
	fly status

# View application logs
fly.logs:
	@echo "📜 Tailing logs..."
	fly logs

# Open remote IEx console
fly.console:
	@echo "💻 Opening remote console..."
	fly ssh console --command "/app/bin/faf_cn remote"

# Connect to production database
fly.db.connect:
	@echo "🗄️  Connecting to production database..."
	fly postgres connect -a faf-cn-db

# Open application in browser
fly.open:
	@echo "🌐 Opening application..."
	fly open

# Show Fly.io configuration
fly.config:
	@echo "⚙️  Fly.io configuration:"
	fly config show

# List all secrets
fly.secrets:
	@echo "🔐 Listing secrets..."
	fly secrets list

# Set a secret (usage: make fly.secrets.set DATABASE_URL=xxx)
fly.secrets.set:
	@echo "🔐 Setting secrets..."
	@if [ -z "$(KEY)" ]; then \
		echo "Usage: make fly.secrets.set KEY=value"; \
		exit 1; \
	fi
	fly secrets set $(KEY)

# Create the Fly.io app (first time setup)
fly.apps.create:
	@echo "📦 Creating Fly.io app..."
	fly apps create faf-cn

# Provision database (first time setup)
fly.db.create:
	@echo "🗄️  Creating PostgreSQL database..."
	fly postgres create --name faf-cn-db --region sin --vm-size shared-cpu-1x

# Attach database to app
fly.db.attach:
	@echo "🔗 Attaching database to app..."
	fly postgres attach faf-cn-db --app faf-cn

# Cleanup
# -------

clean:
	mix clean
	rm -rf _build/

# Kimi CLI
# --------

kimi:
	kimi --mcp-config-file .kimi/mcp.json
