#!/bin/bash
# 비밀번호 해시 생성 스크립트

if [ -z "$1" ]; then
    echo "Usage: $0 <password>"
    echo "Example: $0 appviewx1"
    exit 1
fi

python3 -c "import crypt; print(crypt.crypt('$1', crypt.mksalt(crypt.METHOD_SHA512)))"
