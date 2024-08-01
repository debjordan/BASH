# Script de Gerenciamento de Usuários e Permissões

Este é um script Bash simples para facilitar o gerenciamento de usuários e permissões de arquivos e pastas em sistemas Unix-like. Ele permite criar e deletar usuários, definir permissões de arquivos e pastas, e exibir informações sobre usuários e permissões.

## Funcionalidades

- **Criar Usuário:** Adiciona um novo usuário ao sistema.
- **Deletar Usuário:** Remove um usuário do sistema.
- **Definir Permissões:** Altera as permissões de arquivos e pastas.
- **Exibir Informações:** Lista usuários e exibe permissões de arquivos e pastas.

## Requisitos

- Sistema operacional Unix-like (Linux, macOS, etc.)
- Permissões de superusuário (sudo)

## Instalação


Dê permissão de execução ao script:

bash
Copiar código
chmod +x gerenciar.sh
Uso
Execute o script:

bash
Copiar código
./gerenciar.sh
Escolha uma opção no menu:

1. Criar usuário: Digite o nome do novo usuário.
2. Deletar usuário: Digite o nome do usuário a ser deletado.
3. Definir permissões: Digite o caminho do arquivo ou pasta e as permissões desejadas (ex: 755).
4. Exibir informações:
1. Listar usuários: Mostra a lista de usuários no sistema.
2. Mostrar permissões de um arquivo/pasta: Exibe as permissões do arquivo ou pasta especificado.
5. Sair: Encerra o script.
Exemplo
Para criar um usuário chamado novo_usuario, execute a opção 1 e digite novo_usuario.

Para definir permissões 755 para uma pasta chamada /home/usuario/pasta, escolha a opção 3, forneça o caminho /home/usuario/pasta e as permissões 755.

Contribuição
Sinta-se à vontade para contribuir com melhorias ou correções. Abra um pull request ou issue no repositório
