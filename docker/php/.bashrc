PROMPT_COMMAND=prompter

function prompter() {
    export PS1="\[\e[32m\]Skeleton\[\e[m\] 🔥 \u$(_env)>"
}

function _env() {
    ENV=$( ([[ -f /home/app/.env.local ]] && cat /home/app/.env.local || cat /home/app/.env) | grep "APP_ENV" | cut -f 2 -d"=" )

    echo "(\[\e[33m\]$ENV\[\e[m\])"
}

alias ll="ls -la"
