#!/bin/bash

LINKS_ARQ="links.txt"

add_links() {
   echo "$1" >> "$LINKS_ARQ"
   echo "Link adicionado: $1"
}

lista_links() {
   if [[ -f $LINKS_ARQ ]]; then
	echo "Links:"
	nl -w 2 -s '. ' "LINKS_ARQ"
   else
	echo "Nenhum link encontrado!"
   fi
}

abrir_link() {
   if [[ -f $LINKS_ARQ ]]; then
	LINK=$(sed "${1}q;d" "LINKS_ARQ")
	if [[ ! -z "$LINK" ]]; then
	     echo "Abrindo link: $LINK"
	     curl -s "$LINK" | less
	else
	     echo "Link não encontrado."
	fi
    else
	echo "Nenhum link encontrado"
    fi
}

mostrar_ajuda() {
    echo "Uso: $0 {add|lista|abrir} [argumento]"
    echo "  add [link]           - Adicionar um novo link"
    echo "  lista                - Listar todos os links"
    echo "  abrir [número]       - Abrir um link pelo número"
}

case "$1" in
    add)
	shift
	add_link "$*"
    	;;
    lista)
	lista_links
	;;
    abrir)
	shift
	abrir_link "$1"
	;;
    *)
	mostrar_ajuda
	;;
esac


  
