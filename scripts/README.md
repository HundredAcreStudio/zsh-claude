# Scripts

Automation scripts for zsh-claude development and releases.

## 🚀 create-release.sh

Automated release creation script that handles:

- ✅ Version validation and semantic versioning
- ✅ Git tag creation and pushing
- ✅ GitHub release creation with zsh-claude specific notes
- ✅ README changelog updates
- ✅ Comprehensive error checking

### Usage

```bash
# Create a new patch release
./scripts/create-release.sh v1.0.1

# Create with custom release notes
./scripts/create-release.sh v1.1.0 "Added new AI models and bug fixes"

# Create with release notes from file
./scripts/create-release.sh v1.2.0 CHANGELOG.md
```

### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Clean git working directory
- On main branch (recommended)

### What it does

1. **Validates version format** (semantic versioning)
2. **Checks prerequisites** (gh CLI, git repo, clean working dir)
3. **Updates README.md** changelog section
4. **Creates annotated git tag** with detailed message
5. **Pushes tag** to origin/upstream
6. **Creates GitHub release** with zsh-claude specific formatting
7. **Provides next steps** for users

### Example Output

```
[INFO] Creating release v1.0.1...
[INFO] Updating README.md changelog...
[INFO] Creating git tag: v1.0.1
[INFO] Pushing tag to origin...
[INFO] Using generated zsh-claude release notes
[INFO] Creating GitHub release...
[INFO] Release v1.0.1 created successfully! 🚀
```

The script generates comprehensive release notes including:
- Installation instructions for multiple plugin managers
- Usage examples and keybindings
- Setup instructions with API key links
- Links to documentation

Perfect for maintaining consistent, professional releases! 🎯