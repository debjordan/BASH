# Terminal Tor Browser

Este é um navegador de terminal simples, escrito em Bash, que permite gerenciar e abrir links, incluindo sites .onion na rede Tor.

## Funcionalidades

- Adicionar novos links.
- Listar todos os links armazenados.
- Abrir links usando `curl`, incluindo suporte para sites .onion através da rede Tor.

## Requisitos

- `curl`
- `less`
- `tor`

## Instalação

1. **Clone o repositório (se aplicável)**:
    ```bash
    git clone <URL_DO_REPOSITORIO>
    cd <NOME_DO_DIRETORIO>
    ```

2. **Torne o script executável**:
    ```bash
    chmod +x terminal_browser.sh
    ```

3. **Instale o Tor**:
    ```bash
    sudo apt update
    sudo apt install tor
    ```

4. **Inicie o serviço Tor**:
    ```bash
    sudo systemctl start tor
    ```

## Uso

### Adicionar um link

Para adicionar um novo link:
```bash
./terminal_browser.sh add "http://example.com"


Listar todos os links
Para listar todos os links armazenados:

bash
Copiar código
./terminal_browser.sh list
Abrir um link
Para abrir um link:

bash
Copiar código
./terminal_browser.sh open 1
(O número 1 é o número do link que deseja abrir, conforme listado pelo comando list)

Se o link for um site .onion, o script usará o Tor para acessá-lo.
