#!/usr/bin/env bash

export -p | sed 's/^declare -x //' | grep -v -E "^(HOME|PWD|OLDPWD)" > /etc/environment
