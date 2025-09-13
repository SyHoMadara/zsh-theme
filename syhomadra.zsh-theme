function theme_precmd {
  local TERMWIDTH=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} ))

  PR_FILLBAR=""
  PR_PWDLEN=""

  local promptsize=${#${(%):---%n--::-----}}
  local rubypromptsize=${#${(%)$(ruby_prompt_info)}}
  local pwdsize=${#${(%):-%~}}
  local venvpromptsize=$((${#$(virtualenv_prompt_info)}))
  local condapromptsize=$((${#$(conda_prompt_info)}))

  # Truncate the path if it's too long.
  if (( promptsize + rubypromptsize + pwdsize + venvpromptsize + condapromptsize > TERMWIDTH )); then
    (( PR_PWDLEN = TERMWIDTH - promptsize ))
  elif [[ "${langinfo[CODESET]}" = UTF-8 ]]; then
    PR_FILLBAR="\${(l:$(( TERMWIDTH - (promptsize + rubypromptsize + pwdsize + venvpromptsize + condapromptsize ) ))::${PR_HBAR}:)}"
  else
    PR_FILLBAR="${PR_SHIFT_IN}\${(l:$(( TERMWIDTH - (promptsize + rubypromptsize + pwdsize + venvpromptsize + condapromptsize ) ))::${altchar[q]:--}:)}${PR_SHIFT_OUT}"
  fi
}

function theme_preexec {
  setopt local_options extended_glob
  if [[ "$TERM" = "screen" ]]; then
    local CMD=${1[(wr)^(*=*|sudo|-*)]}
    echo -n "\ek$CMD\e\\"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec


# Set the prompt
typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1


# Need this so the prompt will work.
setopt prompt_subst

# See if we can use colors.
autoload zsh/terminfo
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
  typeset -g PR_$color="%{$terminfo[bold]$fg[${(L)color}]%}"
  typeset -g PR_LIGHT_$color="%{$fg[${(L)color}]%}"
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

# Modify Git prompt
ZSH_THEME_GIT_PROMPT_PREFIX="(%F{#AE75DA}  %F{#FF6363}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%})"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} %{%G%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} %{%G●%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} %{%G●%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} %{%G➜%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} %{%G═%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} %{%G✭%}"

# Use extended characters to look nicer if supported.
if [[ "${langinfo[CODESET]}" = UTF-8 ]]; then
  PR_SET_CHARSET=""
  PR_HBAR=" "
  PR_ULCORNER="┏"
  PR_LLCORNER="┗"
  PR_URCORNER="╮"
  PR_LRCORNER="╯"
else
  typeset -g -A altchar
  set -A altchar ${(s..)terminfo[acsc]}
  # Some stuff to help us draw nice lines
  PR_SET_CHARSET="%{$terminfo[enacs]%}"
  PR_SHIFT_IN="%{$terminfo[smacs]%}"
  PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
  PR_HBAR="${PR_SHIFT_IN}${altchar[q]:--}${PR_SHIFT_OUT}"
  PR_ULCORNER="${PR_SHIFT_IN}${altchar[l]:--}${PR_SHIFT_OUT}"
  PR_LLCORNER="${PR_SHIFT_IN}${altchar[m]:--}${PR_SHIFT_OUT}"
  PR_LRCORNER="${PR_SHIFT_IN}${altchar[j]:--}${PR_SHIFT_OUT}"
  PR_URCORNER="${PR_SHIFT_IN}${altchar[k]:--}${PR_SHIFT_OUT}"
fi

# Decide if we need to set titlebar text.
case $TERM in
  xterm*)
    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
    ;;
  screen)
    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
    ;;
  *)
    PR_TITLEBAR=""
    ;;
esac
# New function to get the Linux distro icon
function get_distro_icon() {
    # Check for /etc/os-release which is the modern standard
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                echo " " # Ubuntu icon
                ;;
            debian)
                echo " " # Debian icon
                ;;
            arch)
                echo " " # Arch Linux icon
                ;;
            fedora)
                echo " " # Fedora icon
                ;;
            centos)
                echo " " # CentOS icon
                ;;
            raspbian)
                echo " " # Raspberry Pi icon
                ;;
            *)
                echo " " # Default Linux Tux icon
                ;;
        esac
    else
        # Fallback for older systems
        if [ -f /etc/arch-release ]; then
            echo " " # Arch Linux
        else
            echo " " # Default Linux Tux icon
        fi
    fi
}

function virtualenv_prompt_info() {
  # Check if the VIRTUAL_ENV variable is set and not empty
  if [[ -n "$VIRTUAL_ENV" ]]; then
    # Print the venv name, preceded by a Python icon
    # basename extracts the last part of the path (the venv name)
    echo " $(basename "$VIRTUAL_ENV")"
  fi
}

# Decide whether to set a screen title
if [[ "$TERM" = "screen" ]]; then
  PR_STITLE=$'%{\ekzsh\e\\%}'
else
  PR_STITLE=""
fi
v="#0A97B0"
typeset -g PR_GREY="%{$terminfo[bold]%F{$v}%}"
CORNER_COLOR="#2EB086"
# Finally, the prompt.
PROMPT='${PR_SET_CHARSET}${PR_STITLE}${(e)PR_TITLEBAR}\
%F{$CORNER_COLOR}${PR_ULCORNER}${PR_HBAR}${PR_GREY}$(get_distro_icon)${PR_HBAR}\
${PR_CYAN}%${PR_PWDLEN}<...<%~%<<\
${PR_CYAN}${PR_HBAR}${PR_HBAR}${(e)PR_FILLBAR}${PR_HBAR}${PR_GREY}\
${PR_CYAN}%(!.%SROOT%s.%n)${PR_GREY}${PR_HBAR}$(virtualenv_prompt_info)$(ruby_prompt_info)$(conda_prompt_info)${PR_GREY}${PR_CYAN}%F{$CORNER_COLOR}${PR_HBAR}${PR_URCORNER}\

%F{$CORNER_COLOR}${PR_LLCORNER}${PR_BLUE}${PR_HBAR}\
${PR_LIGHT_BLUE}%{$reset_color%}$(git_prompt_info)$(git_prompt_status)${PR_BLUE}${PR_HBAR}${PR_CYAN}\
⟶ ${PR_NO_COLOUR} '

# display exitcode on the right when > 0
return_code="%(?..%{$fg[red]%}%? ⤶ %{$reset_color%})"
RPROMPT=' $return_code${PR_HBAR}\
%F{$CORNER_COLOR}${PR_LRCORNER}${PR_NO_COLOUR}'

PS2='${PR_CYAN}${PR_HBAR}\
${PR_BLUE}${PR_HBAR}(\
${PR_LIGHT_GREEN}%_${PR_BLUE})${PR_HBAR}\
${PR_CYAN}${PR_HBAR}${PR_NO_COLOUR} '
