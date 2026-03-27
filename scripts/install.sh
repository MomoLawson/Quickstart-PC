#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_software() {
    local os=$1
    local software_key=$2
    local install_cmd=""
    
    case "$os" in
        windows)
            install_cmd=$(get_yaml_value "$software_key" "win")
            ;;
        macos)
            install_cmd=$(get_yaml_value "$software_key" "mac")
            ;;
        linux)
            install_cmd=$(get_yaml_value "$software_key" "linux")
            ;;
    esac
    
    if [[ -z "$install_cmd" ]]; then
        log_warn "$LANG_PLATFORM_NOT_SUPPORTED: $software_key"
        return 1
    fi
    
    log_step "$LANG_INSTALLING: $software_key"
    eval "$install_cmd" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "$software_key $LANG_INSTALL_SUCCESS"
    else
        log_error "$software_key $LANG_INSTALL_FAILED"
    fi
}

get_yaml_value() {
    local software_key=$1
    local platform=$2
    local yaml_file="$SCRIPT_DIR/../config/profiles.yaml"
    
    local in_software=0
    local in_target=0
    
    while IFS= read -r line; do
        if [[ "$line" == "software:" ]]; then
            in_software=1
            in_target=0
        elif [[ $in_software -eq 1 ]]; then
            local key="${line%%:*}"
            local leading="${key%%[![:space:]]*}"
            local trimmed_key="${key#$leading}"
            
            if [[ "$trimmed_key" == "$software_key" ]]; then
                in_target=1
            fi
            
            if [[ $in_target -eq 1 ]] && [[ "$line" == *${platform}:* ]]; then
                local value="${line#*${platform}:}"
                while [[ "${value:0:1}" == ' ' || "${value:0:1}" == '"' ]]; do
                    value="${value:1}"
                done
                local len=${#value}
                while [[ $len -gt 0 ]]; do
                    local last="${value:$((len-1)):1}"
                    if [[ "$last" == ' ' || "$last" == '"' ]]; then
                        value="${value:0:$((len-1))}"
                        len=$((len-1))
                    else
                        break
                    fi
                done
                echo "$value"
                return
            fi
            
        fi
    done < "$yaml_file"
}

resolve_software_list() {
    local os=$1
    shift
    local profiles=("$@")
    local yaml_file="$SCRIPT_DIR/../config/profiles.yaml"
    
    local in_profiles=0
    local in_target_profile=0
    local in_includes=0
    local current_profile=""
    local sw_list=()
    
    while IFS= read -r line; do
        if [[ "$line" == "profiles:" ]]; then
            in_profiles=1
            in_includes=0
        elif [[ "$line" == "software:" ]]; then
            in_profiles=0
            in_includes=0
        elif [[ $in_profiles -eq 1 ]]; then
            if [[ $line =~ ^[[:space:]]{2}([a-z_][a-z0-9_]*): ]]; then
                current_profile="${BASH_REMATCH[1]}"
                if [[ " ${profiles[*]} " =~ " ${current_profile} " ]]; then
                    in_target_profile=1
                else
                    in_target_profile=0
                fi
                in_includes=0
            elif [[ $in_target_profile -eq 1 ]] && [[ "$line" == *"includes:" ]]; then
                in_includes=1
            elif [[ $in_includes -eq 1 ]] && [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]+[a-z0-9.]+ ]]; then
                local sw="${line##*- }"
                sw_list+=("$sw")
            fi
        fi
    done < "$yaml_file"
    
    printf '%s\n' "${sw_list[@]}" | sort -u
}
