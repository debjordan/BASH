#!/bin/bash

LINKS_FILE="links.txt"

add_link() {
    echo "$1" >> "$LINKS_FILE"
    echo "Link adicionado: $1"
}

list_links() {
    if [[ -f $LINKS_FILE ]]; then
        echo "Links:"
        nl -w 2 -s '. ' "$LINKS_FILE"
    else
        echo "Nenhum link encontrado."
    fi
}

open_link() {
    if [[ -f $LINKS_FILE ]]; then
        LINK=$(sed "${1}q;d" "$LINKS_FILE")
        if [	 ! -z "$LINK" ]]; then
            if [[ $LINK == *.onion ]]; then
                echo "Abrindo link .onion usando Tor: $LINK"
                curl --socks5-hostname localhost:9050 -s "$LINK" | less
            else
                echo "Abrindo link: $LINK"
                curl -s "$LINK" | less
            fi
        else
            echo "Link não encontrado."
        fi
    else
        echo "Nenhum link encontrado."
    fi
}

show_help() {
    echo "Uso: $0 {add|list|open} [argumento]"
    echo "  add [link]       - Adicionar um novo link"
    echo "  list             - Listar todos os links"
    echo "  open [número]    - Abrir um link pelo número"
}

case "$1" in
    add)
        shift
        add_link "$*"
        ;;
    list)
        list_links
        ;;
    open)
        shift
        open_link "$1"
        ;;
    *)
        show_help
        ;;
esac


