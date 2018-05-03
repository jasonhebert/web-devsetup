# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

## Display prompt in green
export PS1="\[\033[38;5;2m\][\u@\h \W]\$ \[$(tput sgr0)\]"
