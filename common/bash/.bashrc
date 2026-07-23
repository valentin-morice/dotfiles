#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# bash has no always-sourced env file (zsh has .zshenv), so mirror the essentials
# here for interactive bash (TTY login, rescue shell): the 1Password SSH agent
# (git auth/signing), an editor, and cargo/bun on PATH.
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
export PATH="$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"
if command -v nvim >/dev/null; then export EDITOR=nvim VISUAL=nvim
elif command -v vim >/dev/null; then export EDITOR=vim VISUAL=vim
else export EDITOR=vi VISUAL=vi; fi
