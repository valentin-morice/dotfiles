#!/usr/bin/env bash
# Claude Code statusline. Extracted from the inline settings.json one-liner: it
# pulls every JSON field in ONE jq pass (the inline version forked jq ~8x on
# every render) and formats the line. Wired via ~/.claude/settings.json ->
# statusLine.command. No `set -e`: a statusline must never abort mid-render.

input=$(cat)

# One jq pass, one field per line (empty fields become empty lines). // "" — not
# // empty — keeps a placeholder line for missing fields so `read` stays aligned;
# reading line-by-line avoids the tab/IFS-whitespace collapse that would drop
# empty fields with a single @tsv read.
{
    IFS= read -r cwd
    IFS= read -r session
    IFS= read -r plan
    IFS= read -r used_pct
    IFS= read -r ctx_size
    IFS= read -r cost
    IFS= read -r duration_ms
    IFS= read -r model
} < <(printf '%s' "$input" | jq -r '
    .workspace.current_dir // "",
    .session_name // "",
    .plan.name // "",
    (.context_window.used_percentage // "" | tostring),
    (.context_window.context_window_size // 0 | tostring),
    (.cost.total_cost_usd // 0 | tostring),
    (.cost.total_duration_ms // 0 | tostring),
    .model.display_name // ""')

dir=$(basename "$cwd")
cd "$cwd" 2>/dev/null || true

dim="\033[2m"; reset="\033[0m"; green="\033[32m"; yellow="\033[33m"; red="\033[31m"
sep=$(printf " ${dim}|${reset} ")
# Nerd Font glyphs as UTF-8 octal escapes (pure-ASCII source, unmanglable — the
# same technique the rofi-* menus use). Codepoints: session U+F489, folder
# U+F07B, branch U+E729, model U+F06A9, brain U+E28C, dollar U+F155, clock
# U+F017, plan U+F0AE.
i_session=$(printf '\357\222\211'); i_folder=$(printf '\357\201\273'); i_branch=$(printf '\356\234\251')
i_model=$(printf '\363\260\232\251'); i_brain=$(printf '\356\212\214'); i_dollar=$(printf '\357\205\225')
i_clock=$(printf '\357\200\227'); i_plan=$(printf '\357\202\256')

git_info=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
        || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    [ ${#branch} -gt 20 ] && branch="${branch:0:19}…"
    if ! git --no-optional-locks diff --quiet 2>/dev/null \
       || ! git --no-optional-locks diff --cached --quiet 2>/dev/null; then
        status_icon=$(printf "${yellow}*${reset}")
    else
        status_icon=$(printf "${green}*${reset}")
    fi
    git_info=$(printf "${sep}${i_branch} %s %s" "$branch" "$status_icon")
fi

session_info=""; folder_sep=""
if [ -n "$session" ]; then
    session_info=$(printf "${i_session} %s" "$session")
    folder_sep="$sep"
fi

plan_info=""
[ -n "$plan" ] && plan_info=$(printf "${sep}${i_plan} %s" "$plan")

context_info=""
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    if [ "$used_int" -ge 90 ]; then ctx_color="$red"
    elif [ "$used_int" -ge 75 ]; then ctx_color="$yellow"
    else ctx_color="$green"; fi
    used_k=$((ctx_size * used_int / 100 / 1000))
    total_k=$((ctx_size / 1000))
    context_info=$(printf "${sep}${i_brain} ${ctx_color}%.1f%%${reset} ${dim}%dk/%dk${reset}" "$used_pct" "$used_k" "$total_k")
fi

cost_info=""
if [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
    cost_info=$(printf "${sep}${i_dollar} %.4f" "$cost")
fi

duration_info=""
if [ "$duration_ms" != "0" ] && [ "$duration_ms" != "null" ]; then
    total_secs=$((duration_ms / 1000)); mins=$((total_secs / 60)); secs=$((total_secs % 60))
    if [ "$mins" -gt 0 ]; then duration_info=$(printf "${sep}${i_clock} %dm%ds" "$mins" "$secs")
    else duration_info=$(printf "${sep}${i_clock} %ds" "$secs"); fi
fi

model_info=""
[ -n "$model" ] && model_info=$(printf "${sep}${i_model} ${dim}%s${reset}" "$model")

printf "%s%s${i_folder} %s%s%s%s%s%s%s" \
    "$session_info" "$folder_sep" "$dir" "$plan_info" "$git_info" "$model_info" "$context_info" "$cost_info" "$duration_info"
