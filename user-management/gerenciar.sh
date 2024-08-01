#!/bin/bash
if [ $EUID -ne 0 ]; then
    echo "Execulte esse script com 'sudo'."
    exit 1
fi

criar_usuario() {
    echo "Digite o nome do novo usuário:"
    read nome_usuario
    sudo useradd -m "$nome_usuario"
    echo "Usuário $nome_usuario criado com sucesso!"
}

deletar_usuario() {
    echo "Digite o nome do usuário a ser deletado:"
    read nome_usuario
    sudo userdel -r "$nome_usuario"
    echo "Usuário $nome_usuario deletado com sucesso!"
}

definir_permissoes() {
    echo "Digite o caminho do arquivo ou pasta:"
    read caminho
    echo "Digite a permissão (ex: 755, 644):"
    read permissao
    sudo chmod "$permissao" "$caminho"
    echo "Permissão $permissao definida para $caminho!"
}

exibir_info() {
    echo "Escolha uma opção:"
    echo "1. Listar usuários"
    echo "2. Mostrar permissões de um arquivo/pasta"
    read opcao
    case $opcao in
        1)
            cut -d: -f1 /etc/passwd
            ;;
        2)
            echo "Digite o caminho do arquivo ou pasta:"
            read caminho
            ls -l "$caminho"
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
}

while true; do
    echo "Escolha uma opção:"
    echo "1. Criar usuário"
    echo "2. Deletar usuário"
    echo "3. Definir permissões"
    echo "4. Exibir informações"
    echo "5. Sair"
    read escolha
    case $escolha in
        1)
            criar_usuario
            ;;
        2)
            deletar_usuario
            ;;
        3)
            definir_permissoes
            ;;
        4)
            exibir_info
            ;;
        5)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done

