#!/usr/bin/env zsh

# zsh-claude - Standalone AI-powered command line assistant for Zsh
# Provides intelligent command suggestions and explanations using Claude AI

typeset -g ZSH_CLAUDE_TEMP_FILE
typeset -g ZSH_CLAUDE_CONFIG_DIR="${HOME}/.config/zsh-claude"
typeset -g ZSH_CLAUDE_CONFIG_FILE="${ZSH_CLAUDE_CONFIG_DIR}/config"

# Color definitions for output
typeset -g ZSH_CLAUDE_RED='\033[0;31m'
typeset -g ZSH_CLAUDE_GREEN='\033[0;32m'
typeset -g ZSH_CLAUDE_YELLOW='\033[1;33m'
typeset -g ZSH_CLAUDE_BLUE='\033[0;34m'
typeset -g ZSH_CLAUDE_NC='\033[0m' # No Color

# Default configuration
typeset -g ZSH_CLAUDE_API_KEY=""
typeset -g ZSH_CLAUDE_API_URL="https://api.anthropic.com/v1/messages"
typeset -g ZSH_CLAUDE_MODEL="claude-3-5-haiku-20241022"
typeset -g ZSH_CLAUDE_MAX_TOKENS="1000"
typeset -g ZSH_CLAUDE_USE_LITELLM="false"

# Load configuration from file
_zsh_claude_load_config() {
    if [[ -f "$ZSH_CLAUDE_CONFIG_FILE" ]]; then
        source "$ZSH_CLAUDE_CONFIG_FILE"
    fi
}

# Save configuration to file
_zsh_claude_save_config() {
    mkdir -p "$ZSH_CLAUDE_CONFIG_DIR"
    cat > "$ZSH_CLAUDE_CONFIG_FILE" << EOF
# zsh-claude configuration
ZSH_CLAUDE_API_KEY="$ZSH_CLAUDE_API_KEY"
ZSH_CLAUDE_API_URL="$ZSH_CLAUDE_API_URL"
ZSH_CLAUDE_MODEL="$ZSH_CLAUDE_MODEL"
ZSH_CLAUDE_MAX_TOKENS="$ZSH_CLAUDE_MAX_TOKENS"
ZSH_CLAUDE_USE_LITELLM="$ZSH_CLAUDE_USE_LITELLM"
EOF
}

# Setup configuration interactively
_zsh_claude_setup() {
    printf "${ZSH_CLAUDE_BLUE}zsh-claude setup${ZSH_CLAUDE_NC}\n"

    # Show current configuration if it exists
    if [[ -n "$ZSH_CLAUDE_API_KEY" ]]; then
        local masked_key="${ZSH_CLAUDE_API_KEY:0:8}...${ZSH_CLAUDE_API_KEY: -4}"
        printf "Current API Key: ${ZSH_CLAUDE_GREEN}$masked_key${ZSH_CLAUDE_NC}\n"
        printf "Current Model: ${ZSH_CLAUDE_GREEN}$ZSH_CLAUDE_MODEL${ZSH_CLAUDE_NC}\n\n"
        printf "Do you want to update your configuration? [y/N]: "
        local update_config
        read update_config
        if [[ ! "$update_config" =~ ^[Yy]$ ]]; then
            printf "Configuration unchanged.\n"
            return 0
        fi
        printf "\n"
    fi

    # API Key configuration
    if [[ -n "$ZSH_CLAUDE_API_KEY" ]]; then
        printf "Do you want to update your API key? [y/N]: "
        local update_key
        read update_key
        if [[ "$update_key" =~ ^[Yy]$ ]]; then
            printf "Enter new API key: "
            local new_api_key
            read -s new_api_key
            printf "\n"
            if [[ -n "$new_api_key" ]]; then
                ZSH_CLAUDE_API_KEY="$new_api_key"
                printf "${ZSH_CLAUDE_GREEN}✓ API key updated${ZSH_CLAUDE_NC}\n"
            else
                printf "${ZSH_CLAUDE_YELLOW}No API key entered, keeping current${ZSH_CLAUDE_NC}\n"
            fi
        else
            printf "${ZSH_CLAUDE_BLUE}Keeping current API key${ZSH_CLAUDE_NC}\n"
        fi
    else
        printf "Please provide your Claude API key.\n"
        printf "You can get one from: https://console.anthropic.com/\n\n"
        printf "API Key: "
        read -s ZSH_CLAUDE_API_KEY
        printf "\n"

        if [[ -z "$ZSH_CLAUDE_API_KEY" ]]; then
            printf "${ZSH_CLAUDE_RED}Error: API key is required${ZSH_CLAUDE_NC}\n"
            return 1
        fi
    fi

    # LiteLLM proxy configuration
    printf "\n${ZSH_CLAUDE_BLUE}LiteLLM Proxy Configuration:${ZSH_CLAUDE_NC}\n"
    printf "Do you want to use LiteLLM proxy? [y/N]: "
    local use_litellm
    read use_litellm
    if [[ "$use_litellm" =~ ^[Yy]$ ]]; then
        ZSH_CLAUDE_USE_LITELLM="true"
        printf "${ZSH_CLAUDE_GREEN}✓ LiteLLM proxy enabled${ZSH_CLAUDE_NC}\n"

        printf "\nEnter LiteLLM proxy URL (e.g., http://localhost:4000/v1/messages): "
        local proxy_url
        read proxy_url
        if [[ -n "$proxy_url" ]]; then
            ZSH_CLAUDE_API_URL="$proxy_url"
            printf "${ZSH_CLAUDE_GREEN}✓ Proxy URL set to: $proxy_url${ZSH_CLAUDE_NC}\n"
        else
            printf "${ZSH_CLAUDE_YELLOW}No URL entered, keeping current: $ZSH_CLAUDE_API_URL${ZSH_CLAUDE_NC}\n"
        fi
    else
        ZSH_CLAUDE_USE_LITELLM="false"
        # Reset to default Anthropic API if not using LiteLLM
        if [[ "$ZSH_CLAUDE_API_URL" != "https://api.anthropic.com/v1/messages" ]]; then
            printf "Reset API URL to Anthropic default? [Y/n]: "
            local reset_url
            read reset_url
            if [[ ! "$reset_url" =~ ^[Nn]$ ]]; then
                ZSH_CLAUDE_API_URL="https://api.anthropic.com/v1/messages"
                printf "${ZSH_CLAUDE_GREEN}✓ API URL reset to default${ZSH_CLAUDE_NC}\n"
            fi
        fi
    fi

    # Model selection
    printf "\n${ZSH_CLAUDE_BLUE}Choose a Claude model:${ZSH_CLAUDE_NC}\n"

    local current_choice=""
    case "$ZSH_CLAUDE_MODEL" in
        "claude-3-5-haiku-20241022") current_choice=" ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}" ;;
        "claude-3-7-sonnet-20250219") current_choice="" ;;
        "claude-sonnet-4-20250514") current_choice="" ;;
        "claude-sonnet-4-5-20250929") current_choice="" ;;
        "claude-opus-4-1-20250805") current_choice="" ;;
    esac

    printf "1) claude-3-5-haiku-20241022    (Fast, cost-effective)$([[ "$ZSH_CLAUDE_MODEL" == "claude-3-5-haiku-20241022" ]] && printf " ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}" || printf " ${ZSH_CLAUDE_GREEN}[Recommended]${ZSH_CLAUDE_NC}")\n"
    printf "2) claude-3-7-sonnet-20250219   (Balanced performance)$([[ "$ZSH_CLAUDE_MODEL" == "claude-3-7-sonnet-20250219" ]] && printf " ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}")\n"
    printf "3) claude-sonnet-4-20250514     (Most capable, higher cost)$([[ "$ZSH_CLAUDE_MODEL" == "claude-sonnet-4-20250514" ]] && printf " ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}")\n"
    printf "4) claude-sonnet-4-5-20250929   (Latest Sonnet 4.5)$([[ "$ZSH_CLAUDE_MODEL" == "claude-sonnet-4-5-20250929" ]] && printf " ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}")\n"
    printf "5) claude-opus-4-1-20250805     (Premium, highest cost)$([[ "$ZSH_CLAUDE_MODEL" == "claude-opus-4-1-20250805" ]] && printf " ${ZSH_CLAUDE_GREEN}[Current]${ZSH_CLAUDE_NC}")\n"

    # Set default based on current model
    local default_choice=1
    case "$ZSH_CLAUDE_MODEL" in
        "claude-3-5-haiku-20241022") default_choice=1 ;;
        "claude-3-7-sonnet-20250219") default_choice=2 ;;
        "claude-sonnet-4-20250514") default_choice=3 ;;
        "claude-sonnet-4-5-20250929") default_choice=4 ;;
        "claude-opus-4-1-20250805") default_choice=5 ;;
    esac

    printf "\nEnter your choice [1-5] (default: $default_choice): "

    local choice
    read choice
    choice="${choice:-$default_choice}"

    case "$choice" in
        1)
            ZSH_CLAUDE_MODEL="claude-3-5-haiku-20241022"
            printf "Selected: Claude 3.5 Haiku (fast and efficient)\n"
            ;;
        2)
            ZSH_CLAUDE_MODEL="claude-3-7-sonnet-20250219"
            printf "Selected: Claude 3.7 Sonnet (balanced performance)\n"
            ;;
        3)
            ZSH_CLAUDE_MODEL="claude-sonnet-4-20250514"
            printf "Selected: Claude Sonnet 4 (high performance)\n"
            ;;
        4)
            ZSH_CLAUDE_MODEL="claude-sonnet-4-5-20250929"
            printf "Selected: Claude Sonnet 4.5 (latest model)\n"
            ;;
        5)
            ZSH_CLAUDE_MODEL="claude-opus-4-1-20250805"
            printf "Selected: Claude Opus 4.1 (premium)\n"
            ;;
        *)
            printf "${ZSH_CLAUDE_YELLOW}Invalid choice, keeping current model: $ZSH_CLAUDE_MODEL${ZSH_CLAUDE_NC}\n"
            ;;
    esac

    _zsh_claude_save_config
    printf "\n${ZSH_CLAUDE_GREEN}✓ Configuration saved to $ZSH_CLAUDE_CONFIG_FILE${ZSH_CLAUDE_NC}\n"
    printf "  Model: $ZSH_CLAUDE_MODEL\n"
    return 0
}

# Check if required dependencies are available
_zsh_claude_check_dependencies() {
    local missing_deps=()

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        printf "${ZSH_CLAUDE_RED}Error: Missing required dependencies:${ZSH_CLAUDE_NC}\n" >&2
        for dep in "${missing_deps[@]}"; do
            printf "  - %s\n" "$dep" >&2
        done
        printf "\n${ZSH_CLAUDE_YELLOW}Please install the missing dependencies and try again.${ZSH_CLAUDE_NC}\n" >&2
        return 1
    fi

    # Check API key
    if [[ -z "$ZSH_CLAUDE_API_KEY" ]]; then
        printf "${ZSH_CLAUDE_YELLOW}No API key found. Run 'claude-setup' to configure.${ZSH_CLAUDE_NC}\n" >&2
        return 1
    fi

    return 0
}

# Show a spinner while waiting for background process
_zsh_claude_spinner() {
    local pid=$1
    local message=$2
    local delay=0.15
    local spinstr='🤔💭🧠✨'

    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "%s" "${spinstr:0:1}"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b"
    done
}

# Call Claude API for AI assistance
_zsh_claude_api_call() {
    local prompt="$1"
    local system_prompt="$2"
    local temp_file="$3"

    local json_payload=$(jq -n \
        --arg model "$ZSH_CLAUDE_MODEL" \
        --arg system "$system_prompt" \
        --arg prompt "$prompt" \
        --argjson max_tokens "$ZSH_CLAUDE_MAX_TOKENS" \
        '{
            model: $model,
            max_tokens: $max_tokens,
            system: $system,
            messages: [
                {
                    role: "user",
                    content: $prompt
                }
            ]
        }')

    # Use different headers based on whether LiteLLM is enabled
    if [[ "$ZSH_CLAUDE_USE_LITELLM" == "true" ]]; then
        curl -s -X POST "$ZSH_CLAUDE_API_URL" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ZSH_CLAUDE_API_KEY" \
            -d "$json_payload" > "$temp_file"
    else
        curl -s -X POST "$ZSH_CLAUDE_API_URL" \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ZSH_CLAUDE_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$json_payload" > "$temp_file"
    fi
}

# Extract content from Claude API response
_zsh_claude_extract_content() {
    local response_file="$1"

    if [[ ! -f "$response_file" ]]; then
        return 1
    fi

    # Check for API errors
    if jq -e '.error' "$response_file" &>/dev/null; then
        local error_msg=$(jq -r '.error.message // .error' "$response_file" 2>/dev/null)
        printf "${ZSH_CLAUDE_RED}API Error: %s${ZSH_CLAUDE_NC}\n" "$error_msg" >&2
        return 1
    fi

    # Extract the content from the response
    jq -r '.content[0].text // empty' "$response_file" 2>/dev/null
}

# Generate command suggestions using Claude AI
zsh_claude_suggest() {
    if ! _zsh_claude_check_dependencies; then
        zle redisplay
        return 1
    fi

    # If buffer is empty, do nothing
    if [[ -z "$BUFFER" ]]; then
        return 0
    fi

    # Move cursor to end of line
    CURSOR=$#BUFFER

    # Create temporary file for output
    ZSH_CLAUDE_TEMP_FILE=$(mktemp)

    # Save current command to history before replacing
    print -s "$BUFFER"

    local system_prompt="You are a command-line assistant. Given a natural language description or partial command, provide a single, executable shell command that accomplishes the task. Respond with ONLY the command, no explanations or additional text."

    # Call Claude API in background (suppress job control output)
    setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR
    {
        _zsh_claude_api_call "$BUFFER" "$system_prompt" "$ZSH_CLAUDE_TEMP_FILE"
    } &>/dev/null &
    local api_pid=$!

    # Show spinner while waiting
    echo -e " ${ZSH_CLAUDE_BLUE}Getting suggestion...${ZSH_CLAUDE_NC}  \c"
    _zsh_claude_spinner $api_pid ""

    # Wait for background process to complete
    wait $api_pid
    local exit_code=$?

    # Extract the suggestion
    local suggestion
    if [[ $exit_code -eq 0 ]]; then
        suggestion=$(_zsh_claude_extract_content "$ZSH_CLAUDE_TEMP_FILE")
    fi

    # Clean up temp file
    rm -f "$ZSH_CLAUDE_TEMP_FILE"

    # Clear the spinner line
    printf "\r\033[K"

    if [[ -n "$suggestion" ]]; then
        # Replace buffer with suggestion
        BUFFER="$suggestion"
        CURSOR=$#BUFFER
        # Don't print anything - just replace the command
    else
        echo -e "${ZSH_CLAUDE_RED}✗ No suggestion found${ZSH_CLAUDE_NC}"
    fi

    zle redisplay
}

# Explain the current command using Claude AI
zsh_claude_explain() {
    if ! _zsh_claude_check_dependencies; then
        zle redisplay
        return 1
    fi

    # If buffer is empty, do nothing
    if [[ -z "$BUFFER" ]]; then
        return 0
    fi

    # Create temporary file for output
    ZSH_CLAUDE_TEMP_FILE=$(mktemp)

    local system_prompt="You are a command-line expert. Explain what the given shell command does in clear, concise terms. Include what each part of the command does and any important notes about usage or potential risks."

    # Call Claude API in background (suppress job control output)
    setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR
    {
        _zsh_claude_api_call "$BUFFER" "$system_prompt" "$ZSH_CLAUDE_TEMP_FILE"
    } &>/dev/null &
    local api_pid=$!

    # Show spinner while waiting
    echo -e " ${ZSH_CLAUDE_BLUE}Getting explanation...${ZSH_CLAUDE_NC}  \c"
    _zsh_claude_spinner $api_pid ""

    # Wait for background process to complete
    wait $api_pid
    local exit_code=$?

    # Extract the explanation
    local explanation
    if [[ $exit_code -eq 0 ]]; then
        explanation=$(_zsh_claude_extract_content "$ZSH_CLAUDE_TEMP_FILE")
    fi

    # Clean up temp file
    rm -f "$ZSH_CLAUDE_TEMP_FILE"

    # Clear the spinner line
    printf "\r\033[K"

    if [[ -n "$explanation" ]]; then
        echo -e "\n${ZSH_CLAUDE_GREEN}Explanation:${ZSH_CLAUDE_NC}"
        printf "%s\n" "$explanation"
    else
        echo -e "\n${ZSH_CLAUDE_RED}✗ No explanation available${ZSH_CLAUDE_NC}"
    fi

    zle redisplay
}

# Register widgets with zle
zle -N zsh_claude_suggest
zle -N zsh_claude_explain

# Default keybindings
# For Linux/Windows: Alt+\ (suggest), Alt+Shift+\ (explain)
# For macOS: Option+\ (suggest), Option+Shift+\ (explain)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS keybindings
    bindkey "∖" zsh_claude_suggest      # Option+\
    bindkey "„" zsh_claude_explain      # Option+Shift+\
else
    # Linux/Windows keybindings
    bindkey "^[\\" zsh_claude_suggest   # Alt+\
    bindkey "^[|" zsh_claude_explain    # Alt+Shift+\
fi

# Cleanup function for temporary files
_zsh_claude_cleanup() {
    if [[ -n "$ZSH_CLAUDE_TEMP_FILE" && -f "$ZSH_CLAUDE_TEMP_FILE" ]]; then
        rm -f "$ZSH_CLAUDE_TEMP_FILE"
    fi
}

# Set up cleanup trap
trap _zsh_claude_cleanup EXIT

# Manual command functions
claude-suggest() {
    local query="$*"
    if [[ -z "$query" ]]; then
        printf "${ZSH_CLAUDE_RED}Usage: claude-suggest <description>${ZSH_CLAUDE_NC}\n"
        return 1
    fi

    if ! _zsh_claude_check_dependencies; then
        return 1
    fi

    local temp_file=$(mktemp)
    local system_prompt="You are a command-line assistant. Given a natural language description, provide a single, executable shell command that accomplishes the task. Respond with ONLY the command, no explanations or additional text."

    printf "${ZSH_CLAUDE_BLUE}Getting suggestion for: %s${ZSH_CLAUDE_NC}\n" "$query"

    _zsh_claude_api_call "$query" "$system_prompt" "$temp_file"
    local suggestion=$(_zsh_claude_extract_content "$temp_file")
    rm -f "$temp_file"

    if [[ -n "$suggestion" ]]; then
        printf "${ZSH_CLAUDE_GREEN}Suggestion:${ZSH_CLAUDE_NC} %s\n" "$suggestion"
    else
        printf "${ZSH_CLAUDE_RED}✗ No suggestion found${ZSH_CLAUDE_NC}\n"
    fi
}

claude-explain() {
    local command="$*"
    if [[ -z "$command" ]]; then
        printf "${ZSH_CLAUDE_RED}Usage: claude-explain <command>${ZSH_CLAUDE_NC}\n"
        return 1
    fi

    if ! _zsh_claude_check_dependencies; then
        return 1
    fi

    local temp_file=$(mktemp)
    local system_prompt="You are a command-line expert. Explain what the given shell command does in clear, concise terms. Include what each part of the command does and any important notes about usage or potential risks."

    printf "${ZSH_CLAUDE_BLUE}Getting explanation for: %s${ZSH_CLAUDE_NC}\n" "$command"

    _zsh_claude_api_call "$command" "$system_prompt" "$temp_file"
    local explanation=$(_zsh_claude_extract_content "$temp_file")
    rm -f "$temp_file"

    if [[ -n "$explanation" ]]; then
        printf "${ZSH_CLAUDE_GREEN}Explanation:${ZSH_CLAUDE_NC}\n%s\n" "$explanation"
    else
        printf "${ZSH_CLAUDE_RED}✗ No explanation available${ZSH_CLAUDE_NC}\n"
    fi
}

claude-setup() {
    _zsh_claude_setup
}

# Load configuration on startup
_zsh_claude_load_config

# Print loading message only if not using instant prompt or if explicitly enabled
if [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" || "$ZSH_CLAUDE_VERBOSE" == "1" ]]; then
    printf "${ZSH_CLAUDE_GREEN}✓ zsh-claude loaded${ZSH_CLAUDE_NC}\n"

    if _zsh_claude_check_dependencies; then
        printf "  ${ZSH_CLAUDE_GREEN}✓ Ready to use${ZSH_CLAUDE_NC}\n"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            printf "  ${ZSH_CLAUDE_BLUE}Keybindings: Option+\\ (suggest), Option+Shift+\\ (explain)${ZSH_CLAUDE_NC}\n"
        else
            printf "  ${ZSH_CLAUDE_BLUE}Keybindings: Alt+\\ (suggest), Alt+Shift+\\ (explain)${ZSH_CLAUDE_NC}\n"
        fi
    else
        printf "  ${ZSH_CLAUDE_YELLOW}Run 'claude-setup' to configure${ZSH_CLAUDE_NC}\n"
    fi
fi