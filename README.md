# zsh-claude

🤖 AI-powered command suggestions and explanations for Zsh using Claude AI. Get intelligent shell command help with simple keybindings.

Transform natural language into executable shell commands, or get detailed explanations of complex commands - all directly in your terminal with Claude AI integration.

## ✨ Features

- **🧠 Smart Suggestions**: Type natural language, get executable commands
- **📖 Command Explanations**: Understand what complex commands do
- **⚡ Interactive**: Simple keybindings for instant access
- **🔒 Standalone**: No GitHub CLI dependencies required
- **🎯 Multiple AI Models**: Choose from Claude 3.5 Haiku to Opus 4.1
- **🔧 Easy Setup**: One-command configuration
- **📦 Plugin Manager Support**: Works with oh-my-zsh, zinit, antigen, zplug

## 🚀 Quick Start

### Prerequisites

1. **Claude API Key**: Get one from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. **curl**: For API requests (usually pre-installed)
3. **jq**: For JSON parsing
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt install jq

   # CentOS/RHEL
   sudo yum install jq
   ```

## 📦 Installation

### Method 1: Oh My Zsh (Recommended)

```bash
# Clone the plugin
git clone https://github.com/HundredAcreStudio/zsh-claude ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-claude

# Add to your ~/.zshrc plugins list
plugins=(... zsh-claude)

# Reload your shell
source ~/.zshrc
```

### Method 2: Zinit

```bash
# Add to ~/.zshrc
zinit load HundredAcreStudio/zsh-claude

# Reload shell
source ~/.zshrc
```

### Method 3: Manual Installation

```bash
# Clone the repository
git clone https://github.com/HundredAcreStudio/zsh-claude ~/.zsh-claude

# Add to ~/.zshrc
echo 'source ~/.zsh-claude/zsh-claude.plugin.zsh' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Other Plugin Managers

<details>
<summary>Click to expand</summary>

**Antigen:**
```bash
antigen bundle HundredAcreStudio/zsh-claude
```

**Zplug:**
```bash
zplug "HundredAcreStudio/zsh-claude"
```

</details>

## ⚙️ Configuration

After installation, run the setup command:

```bash
claude-setup
```

This interactive setup will:
1. Prompt for your Claude API key
2. Let you choose your preferred AI model
3. Save configuration securely to `~/.config/zsh-claude/config`

**Available Models:**
- **Claude 3.5 Haiku** (fast, cost-effective) - Recommended
- **Claude 3.7 Sonnet** (balanced performance)
- **Claude Sonnet 4** (high performance, higher cost)
- **Claude Opus 4.1** (premium, highest cost)

## 🎯 Usage

### Keybindings

| Platform | Suggest Command | Explain Command |
|----------|----------------|-----------------|
| **macOS** | `Option + \` (`«`) | `Option + Shift + \` (`»`) |
| **Linux/Windows** | `Alt + \` | `Alt + Shift + \` |

> **macOS Note:** The actual characters produced are `«` for suggestions and `»` for explanations

### 💡 Command Suggestions

Transform natural language into executable commands:

1. **Type your request:**
   ```
   find all python files modified in the last week
   ```

2. **Press the suggestion key** (Option+\\ on macOS, Alt+\\ on Linux/Windows)

3. **Command appears:**
   ```
   find . -name "*.py" -mtime -7
   ```

**More Examples:**
```bash
# What you type → What you get
compress all jpg files → tar -czf images.tar.gz *.jpg
delete all node_modules → find . -name "node_modules" -type d -exec rm -rf {} +
show disk usage by directory → du -sh */ | sort -hr
```

### 📚 Command Explanations

Understand complex commands instantly:

1. **Type or paste a command:**
   ```
   find . -type f -name "*.log" -exec grep -l "ERROR" {} \;
   ```

2. **Press the explanation key** (Option+Shift+\\ on macOS, Alt+Shift+\\ on Linux/Windows)

3. **Get detailed breakdown:**
   ```
   Explanation:
   This command searches for all files with .log extension and finds those containing "ERROR":
   - find . -type f: searches for files starting from current directory
   - -name "*.log": matches files ending with .log
   - -exec grep -l "ERROR" {} \;: runs grep on each file, showing only filenames that contain "ERROR"
   ```

### 🔧 Manual Commands

Use directly from command line:

```bash
# Generate suggestions
claude-suggest "compress all jpg files"

# Explain commands
claude-explain "tar -czf archive.tar.gz *.jpg"

# Reconfigure settings
claude-setup
```

## 🎨 Customization

### Custom Keybindings

The plugin includes default keybindings, but you can customize them in your `~/.zshrc`:

```bash
# Default keybindings (automatically set by plugin)
bindkey '»' zsh_claude_explain    # Option+Shift+\ on macOS
bindkey '«' zsh_claude_suggest    # Option+\ on macOS

# Custom alternatives
bindkey "^[s" zsh_claude_suggest   # Alt+s
bindkey "^[e" zsh_claude_explain   # Alt+e
bindkey "^@" zsh_claude_suggest    # Ctrl+space
```

> **macOS Users:** The actual characters `«` and `»` are produced by Option+\\ and Option+Shift+\\ respectively

### Available Widgets

- `zsh_claude_suggest`: Generate command suggestions
- `zsh_claude_explain`: Explain current command

### Configuration File

Advanced users can edit `~/.config/zsh-claude/config`:

```bash
ZSH_CLAUDE_API_KEY="your-api-key"
ZSH_CLAUDE_MODEL="claude-3-5-haiku-20241022"
ZSH_CLAUDE_API_URL="https://api.anthropic.com/v1/messages"
ZSH_CLAUDE_MAX_TOKENS="1000"
```

### Environment Variables

```bash
# Show loading messages even with Powerlevel10k instant prompt
export ZSH_CLAUDE_VERBOSE=1

# Add to ~/.zshrc before loading the plugin
```

## 🔧 Troubleshooting

### Installation Issues

<details>
<summary>Powerlevel10k instant prompt warning</summary>

**Problem:** Warning about console output during zsh initialization

**Solution:** This is normal behavior. The plugin automatically suppresses loading messages when Powerlevel10k instant prompt is detected.

To see loading messages anyway:
```bash
# Add to ~/.zshrc before loading the plugin
export ZSH_CLAUDE_VERBOSE=1
```

Or suppress the warning by adding to `~/.zshrc`:
```bash
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
```
</details>

<details>
<summary>Missing dependencies</summary>

**Problem:** "Missing required dependencies" error

**Solution:** Install missing tools:
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt install curl jq

# CentOS/RHEL
sudo yum install curl jq
```
</details>

<details>
<summary>API key issues</summary>

**Problem:** "No API key found" error

**Solution:** Run setup:
```bash
claude-setup
```

**Problem:** "API Error: invalid api key"

**Solution:**
1. Get a valid API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
2. Run `claude-setup` to update your key
</details>

### Usage Issues

<details>
<summary>Keybindings not working</summary>

**Problem:** Keys don't trigger suggestions

**Solutions:**
1. Check terminal compatibility
2. Try custom keybindings (see Customization section)
3. Test with manual commands: `claude-suggest "test"`
</details>

<details>
<summary>No suggestions/explanations</summary>

**Problem:** Commands return no results

**Checklist:**
- ✅ Internet connection working
- ✅ API key is valid (`claude-setup`)
- ✅ API credits available
- ✅ Model name is correct
- ✅ Test with: `claude-suggest "list files"`
</details>

<details>
<summary>Performance issues</summary>

**Problem:** Slow responses

**Solutions:**
1. Switch to faster model (Claude 3.5 Haiku)
2. Check internet connection
3. Reduce `ZSH_CLAUDE_MAX_TOKENS` in config
</details>

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Inspiration

This plugin is inspired by:
- [zsh-github-copilot](https://github.com/loiccoyle/zsh-github-copilot) by loiccoyle
- [GitHub Copilot CLI](https://github.com/github/gh-copilot)

## 📋 Changelog

### v1.0.0
- ✨ Standalone Claude AI integration
- 🚀 Command suggestion functionality
- 📖 Command explanation functionality
- 📦 Support for multiple plugin managers
- ⌨️ Cross-platform keybindings
- 🔒 Secure API key management
- 🎯 Multiple AI model support