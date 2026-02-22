#!/bin/bash
# Auto-approve read-only tools (WebSearch, etc.)
# Workaround for known bug: WebSearch prompts despite being in allow list
# See: https://github.com/anthropics/claude-code/issues/11799
echo '{"decision":"allow"}'
