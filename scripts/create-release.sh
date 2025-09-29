#!/bin/bash

# zsh-claude Release Creation Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[zsh-claude]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 <version> [release-notes]"
    echo ""
    echo "Arguments:"
    echo "  version         Version tag (e.g., v1.0.0, v1.2.3-beta)"
    echo "  release-notes   Optional release notes file or text"
    echo ""
    echo "Examples:"
    echo "  $0 v1.0.1"
    echo "  $0 v1.2.0 'Bug fixes and new features'"
    echo "  $0 v1.3.0 CHANGELOG.md"
    echo ""
    echo "This script will:"
    echo "  1. Validate the version format"
    echo "  2. Check if the tag already exists"
    echo "  3. Update version in README changelog"
    echo "  4. Create and push the git tag"
    echo "  5. Create a GitHub release with zsh-claude specific notes"
}

# Validate input
if [[ $# -lt 1 ]]; then
    print_error "Version is required"
    usage
    exit 1
fi

VERSION="$1"
RELEASE_NOTES="$2"

# Validate version format (should start with 'v' and follow semantic versioning)
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., v1.0.0, v1.2.3-beta)"
    exit 1
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is required but not installed."
    print_error "Install it from: https://github.com/cli/cli#installation"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    print_warning "You're not on the main branch (currently on: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborted"
        exit 1
    fi
fi

# Check if tag already exists
if git tag -l | grep -q "^$VERSION$"; then
    print_error "Tag $VERSION already exists"
    exit 1
fi

# Check if there are uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

# Ensure we're up to date
print_status "Updating local repository..."
if git remote | grep -q "origin"; then
    git fetch origin
    git pull origin "$CURRENT_BRANCH"
else
    print_warning "No 'origin' remote found, skipping pull"
fi

print_header "Creating release $VERSION..."

# Update README changelog if it exists
if [[ -f "README.md" ]]; then
    print_status "Updating README.md changelog..."
    # Add new version to changelog if section exists
    if grep -q "## 📋 Changelog" README.md; then
        # Create backup
        cp README.md README.md.bak

        # Insert new version after the changelog header
        awk -v version="$VERSION" '
        /^## 📋 Changelog/ {
            print $0
            print ""
            print "### " version
            print "- Bug fixes and improvements"
            print ""
            next
        }
        { print }
        ' README.md.bak > README.md

        rm README.md.bak
        print_status "Updated changelog in README.md"
    fi
fi

# Create and push the tag
print_status "Creating git tag: $VERSION"

# Create comprehensive tag message
TAG_MESSAGE="🎉 Release $VERSION

Zsh plugin for Claude AI command suggestions and explanations.

Features in this release:
- AI-powered command suggestions
- Command explanations with Claude
- Cross-platform compatibility
- Plugin manager support

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git tag -a "$VERSION" -m "$TAG_MESSAGE"

print_status "Pushing tag to origin..."
git push origin "$VERSION" 2>/dev/null || {
    print_warning "Failed to push to origin, trying upstream..."
    git push upstream "$VERSION" 2>/dev/null || {
        print_error "Failed to push tag to any remote"
        exit 1
    }
}

# Function to generate zsh-claude specific release notes
generate_zsh_claude_release_notes() {
    local version="$1"
    cat << EOF
## 🤖 zsh-claude $version

**AI-powered command suggestions and explanations for Zsh using Claude AI**

### ✨ What's New

- Enhanced AI integration and performance improvements
- Bug fixes and stability enhancements
- Updated documentation and examples

### 🚀 Quick Install

**Oh My Zsh:**
\`\`\`bash
git clone https://github.com/HundredAcreStudio/zsh-claude \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-claude
# Add 'zsh-claude' to plugins in ~/.zshrc
\`\`\`

**Manual:**
\`\`\`bash
git clone https://github.com/HundredAcreStudio/zsh-claude ~/.zsh-claude
echo 'source ~/.zsh-claude/zsh-claude.plugin.zsh' >> ~/.zshrc
\`\`\`

### ⌨️ Usage

- **macOS**: Option+\\ (suggest), Option+Shift+\\ (explain)
- **Linux/Windows**: Alt+\\ (suggest), Alt+Shift+\\ (explain)

### 🔧 Setup

1. Get API key: [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Install dependencies: \`brew install jq\` (macOS) or \`sudo apt install jq\` (Ubuntu)
3. Configure: Run \`claude-setup\`

### 📖 Documentation

See [README.md](README.md) for complete installation and usage instructions.

---
*Transform natural language into executable commands with Claude AI! 🧠→⚡*
EOF
}

# Prepare release notes
RELEASE_NOTES_ARG=""
if [[ -n "$RELEASE_NOTES" ]]; then
    if [[ -f "$RELEASE_NOTES" ]]; then
        # It's a file
        RELEASE_NOTES_ARG="--notes-file $RELEASE_NOTES"
        print_status "Using release notes from file: $RELEASE_NOTES"
    else
        # It's a string
        RELEASE_NOTES_ARG="--notes $RELEASE_NOTES"
        print_status "Using provided release notes"
    fi
else
    # Generate zsh-claude specific release notes
    TEMP_NOTES_FILE=$(mktemp)
    generate_zsh_claude_release_notes "$VERSION" > "$TEMP_NOTES_FILE"
    RELEASE_NOTES_ARG="--notes-file $TEMP_NOTES_FILE"
    print_status "Using generated zsh-claude release notes"

    # Clean up temp file after release creation
    trap "rm -f $TEMP_NOTES_FILE" EXIT
fi

# Create GitHub release
print_status "Creating GitHub release..."
RELEASE_TITLE="🤖 $VERSION: Claude AI for Zsh"

gh release create "$VERSION" \
    --title "$RELEASE_TITLE" \
    $RELEASE_NOTES_ARG

print_status "Release $VERSION created successfully! 🚀"
print_status ""
print_status "🎯 What's available:"
print_status "1. Users can install via git clone or plugin managers"
print_status "2. Tagged source code is available for download"
print_status "3. Release includes installation and usage instructions"
print_status ""

# Get and display the release URL
RELEASE_URL=$(gh release view "$VERSION" --json url -q '.url' 2>/dev/null || echo "")
if [[ -n "$RELEASE_URL" ]]; then
    print_status "🌐 Release URL: $RELEASE_URL"
fi

print_status ""
print_header "Next steps for users:"
print_status "• Get Claude API key from console.anthropic.com/settings/keys"
print_status "• Install dependencies: jq, curl"
print_status "• Clone and configure with claude-setup"
print_status "• Use Option+\\ (macOS) or Alt+\\ (Linux) for suggestions"
print_status ""
print_status "🎉 Happy commanding with Claude AI!"