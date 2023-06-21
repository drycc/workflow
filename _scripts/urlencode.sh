#!/bin/bash
# ref:https://github.com/sixarm/urlencode.sh
#
# URL encode script for encoding text.
#
# Syntax: 
#
#     urlencode <string>
#
# Example:
#
#     $ urlencode "foo bar"
#     foo%20bar
#
# This implementation uses just the shell, 
# with no extra dependencies or languages.
#
# Credit: 
#
#   * https://gist.github.com/cdown/1163649
#
# Links:
#
#   * https://github.com/sixarm/urlencode.sh
#   * https://github.com/sixarm/urldecode.sh
#
# Command: urlencode
# Version: 1.0.0
# Created: 2016-09-12
# Updated: 2016-09-12
# License: MIT
# Contact: Joel Parker Henderson (joel@joelparkerhenderson.com)
##

urlencode() {
    # urlencode <string>

    old_lang=$LANG
    LANG=C
    
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LANG=$old_lang
    LC_COLLATE=$old_lc_collate
}

urlencode "$1"