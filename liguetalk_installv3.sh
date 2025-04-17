#!/bin/bash
set -e

# Detectar o diretório home do usuário real (não root)
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

WINE_DIR="$USER_HOME/.wine"
DOWNLOAD_DIR="$USER_HOME/Downloads"
EXEC_SCRIPT="$USER_HOME/abrir_liguetalk.sh"
DESKTOP_DIR="$USER_HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/LigueTalk.desktop"
EXE_NAME="LigueTalk-3.20.7.exe"
EXE_URL="https://www.microsip.org/download/private/${EXE_NAME}"
EXE_PATH="$DOWNLOAD_DIR/$EXE_NAME"

echo "Home do usuário: $USER_HOME"
echo "Prefixo Wine: $WINE_DIR"

# 1. Adicionar arquitetura i386 e atualizar índices
sudo dpkg --add-architecture i386
sudo apt update

# 2. Instalar dependências
sudo apt install -y wget wine64 wine32

# 3. Verificar instalação do Wine
if ! command -v wine &> /dev/null; then
    echo "Erro: Wine não foi instalado corretamente."
    exit 1
fi

# 4. Preparar diretório de downloads
mkdir -p "$DOWNLOAD_DIR"

# 5. Baixar o instalador, se ainda não existe ou estiver vazio
if [ ! -s "$EXE_PATH" ]; then
    echo "Baixando $EXE_NAME..."
    wget "$EXE_URL" -O "$EXE_PATH"
    if [ $? -ne 0 ] || [ ! -s "$EXE_PATH" ]; then
        echo "Erro: falha ao baixar $EXE_NAME."
        exit 1
    fi
fi

# 6. Executar instalador via Wine
echo "Instalando o LigueTalk com Wine..."
wine "$EXE_PATH"

# 7. Localizar o executável instalado
LIGUETALK_PATH=$(find "$WINE_DIR" -type f -iname 'liguetalk*.exe' 2>/dev/null | head -n1)
if [ -z "$LIGUETALK_PATH" ]; then
    echo "Erro: não foi possível localizar o executável do LigueTalk."
    exit 1
fi

# 8. Ajustar permissões do prefixo Wine para o usuário
sudo chown -R "$SUDO_USER:${SUDO_USER:-$(whoami)}" "$WINE_DIR"
sudo chmod -R u+rwX "$WINE_DIR"

# 9. Criar script de atalho para abrir o LigueTalk
cat > "$EXEC_SCRIPT" <<EOF
#!/bin/bash
wine "$LIGUETALK_PATH"
EOF
chmod +x "$EXEC_SCRIPT"
echo "Script de lançamento criado em: $EXEC_SCRIPT"

# 10. Criar atalho .desktop no diretório de aplicações
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=LigueTalk
Comment=Executar o LigueTalk via Wine
Exec=$EXEC_SCRIPT
Icon=utilities-terminal
Terminal=false
Categories=Utility;Application;
EOF
chmod +x "$DESKTOP_FILE"
echo "Atalho criado em: $DESKTOP_FILE"

echo "Instalação e configuração concluídas com sucesso."
