# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
source $HOME/.git-completion.bash

# https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
source $HOME/.git-prompt.sh

# enable forward search - "ctrl" + "s"
stty -ixon

# Terminal colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Default editor
alias vi=vim
export EDITOR=vim

function git_branch {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function prompt {
  local BLACK="\[\033[0;30m\]"
  local BLACKBOLD="\[\033[1;30m\]"
  local RED="\[\033[0;31m\]"
  local REDBOLD="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local GREENBOLD="\[\033[1;32m\]"
  local YELLOW="\[\033[0;33m\]"
  local YELLOWBOLD="\[\033[1;33m\]"
  local BLUE="\[\033[0;34m\]"
  local BLUEBOLD="\[\033[1;34m\]"
  local PURPLE="\[\033[0;35m\]"
  local PURPLEBOLD="\[\033[1;35m\]"
  local CYAN="\[\033[0;36m\]"
  local CYANBOLD="\[\033[1;36m\]"
  local WHITE="\[\033[0;37m\]"
  local WHITEBOLD="\[\033[1;37m\]"
  local RESETCOLOR="\[\e[00m\]"
  local STY="${STY}" # screen name

  if [ "${STY}" != "" ]; then
    STY="$WHITE[$STY] "
  fi

  export PS1="\n$RED\u$PURPLE@$CYAN\H $YELLOW\w $STY$RESETCOLOR$GREENBOLD\$(git_branch)\n→ $RESETCOLOR"
  export PS2=" | → $RESETCOLOR"
}

prompt

# Shortcuts/alises
alias ll='ls -lshat'
alias chrome_nosecure='open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security'
