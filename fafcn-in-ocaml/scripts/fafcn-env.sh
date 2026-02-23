#!/bin/bash
# FAF CN OCaml Environment Setup Script
# Source this file to activate the fafcn opam switch in your current shell
#
# Usage:
#   source scripts/fafcn-env.sh
#   # or
#   . scripts/fafcn-env.sh
#
# Or from project root:
#   eval $(make shell)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/dune-project" ]; then
    echo "Error: Could not find dune-project. Please run from the fafcn-in-ocaml directory."
    return 1 2>/dev/null || exit 1
fi

echo "Activating fafcn opam switch..."
eval $(opam env --switch=fafcn --set-switch)

# Optional: Change to project directory
# cd "$PROJECT_DIR"

echo "Environment activated! Current OCaml version:"
ocaml --version 2>/dev/null || echo "OCaml not found in PATH"
