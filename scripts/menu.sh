#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/log.sh"

show_menu() {
    local profiles_yaml="$1"
    local selected_ref="$2"
    
    local profile_keys=()
    local profile_names=()
    local profile_icons=()
    local profile_descs=()
    
    local in_profiles=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^profiles: ]]; then
            in_profiles=1
        elif [[ "$line" =~ ^software: ]]; then
            in_profiles=0
        elif [[ $in_profiles -eq 1 ]] && [[ $line =~ ^[[:space:]]{2}([a-z_]+):[[:space:]]*$ ]]; then
            profile_keys+=("${BASH_REMATCH[1]}")
        elif [[ $in_profiles -eq 1 ]] && [[ $line =~ ^[[:space:]]+name:[[:space:]]+\"?([^\"]+)\"? ]]; then
            profile_names+=("${BASH_REMATCH[1]}")
        elif [[ $in_profiles -eq 1 ]] && [[ $line =~ ^[[:space:]]+icon:[[:space:]]+\"?([^\"]+)\"? ]]; then
            profile_icons+=("${BASH_REMATCH[1]}")
        elif [[ $in_profiles -eq 1 ]] && [[ $line =~ ^[[:space:]]+desc:[[:space:]]+\"?([^\"]+)\"? ]]; then
            profile_descs+=("${BASH_REMATCH[1]}")
        fi
    done < "$profiles_yaml"
    
    echo ""
    log_header "$LANG_SELECT_PROFILES"
    echo ""
    
    local num_profiles=${#profile_keys[@]}
    local choices=()
    
    for ((i=0; i<num_profiles; i++)); do
        local key="${profile_keys[i]}"
        local name="${profile_names[i]}"
        local icon="${profile_icons[i]}"
        local desc="${profile_descs[i]}"
        
        echo "  [$((i+1))] ${icon} ${name}"
        echo "      ${desc}"
        echo ""
    done
    
    echo "  [0] $LANG_START_INSTALLATION"
    echo ""
    
    read -p "$LANG_INPUT_OPTIONS: " -a choices
    
    eval "$selected_ref=()"
    for choice in "${choices[@]}"; do
        if [[ $choice =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $num_profiles ]]; then
            local idx=$((choice-1))
            eval "$selected_ref+=('${profile_keys[idx]}')"
        fi
    done
}
