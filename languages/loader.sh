#!/usr/bin/env bash

LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUPPORTED_LANGS=("en-US" "zh-CN")

load_language() {
    local lang="$1"
    
    # Check if language variables are already defined (single file version)
    if [[ -n "$LANG_BANNER_TITLE" ]]; then
        return 0
    fi
    
    # Multi-file version: load from file
    local lang_file="$LANG_DIR/${lang}.sh"
    if [[ -f "$lang_file" ]]; then
        source "$lang_file"
        return 0
    else
        source "$LANG_DIR/en-US.sh"
        return 1
    fi
}

# 检测系统语言
detect_language() {
    local lang=""
    
    # 从环境变量获取
    if [[ -n "$LANG" ]]; then
        lang="${LANG%%.*}"
        lang="${lang%%@*}"
        lang="${lang/_/-}"
    elif [[ -n "$LANGUAGE" ]]; then
        lang="${LANGUAGE%%:*}"
        lang="${lang/_/-}"
    fi
    
    # 匹配支持的语言
    case "$lang" in
        zh-CN|zh_CN|zh_Hans|zh-Hans)
            echo "zh-CN"
            ;;
        zh-TW|zh_TW|zh_Hant|zh-Hant)
            echo "zh-CN"  # 繁体暂时映射到简体
            ;;
        en*|*)
            echo "en-US"
            ;;
    esac
}
