local accent="#5294e2"
local secondary="#e0a552"
local muted="#888888"

MATCH_BRANCH_MAX=25

match_git_prompt_info() {
  local ref
  ref=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    ref=$(git rev-parse --short HEAD 2>/dev/null) || return 0
  if (( ${#ref} > MATCH_BRANCH_MAX )); then
    ref="${ref[1,MATCH_BRANCH_MAX-1]}…"
  fi
  local dirty=""
  if [[ -n $(git status --porcelain --ignore-submodules 2>/dev/null) ]]; then
    dirty="$ZSH_THEME_GIT_PROMPT_DIRTY"
  else
    dirty="$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${dirty}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

PROMPT="%(?:%F{$accent}%1{➜%} :%F{red}%1{➜%} )%f %B%c%b"
PROMPT+=' $(match_git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%F{$muted}git:(%F{$secondary}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{$muted}) %F{yellow}%1{✗%}%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{$muted})%f"
