#!/bin/bash

# Parar o script em caso de erro
set -e

# Diretório home do usuário atual
USER_HOME="$HOME"

# Verifica se Wine está instalado
if ! command -v wine &> /dev/null; then
  echo "❌ Wine não está instalado. Por favor, instale com:"
  echo "sudo apt install --install-recommends winehq-stable"
  exit 1
fi

# Inicializar Wine (cria ~/.wine se ainda não existir)
echo "Inicializando Wine..."
winecfg &>/dev/null || true

# Caminho para download e instalação
INSTALLER_NAME="LigueTalk-3.20.7.exe"
INSTALLER_URL="https://www.microsip.org/download/private/$INSTALLER_NAME"
INSTALLER_PATH="$USER_HOME/Downloads/$INSTALLER_NAME"

# Baixar instalador se não existir
if [ ! -f "$INSTALLER_PATH" ]; then
  echo "Baixando instalador do LigueTalk..."
  wget -O "$INSTALLER_PATH" "$INSTALLER_URL"
fi

# Executar instalador
echo "Executando o instalador do LigueTalk com Wine..."
wine "$INSTALLER_PATH"

# Procurar caminho do executável instalado
echo "Procurando caminho do LigueTalk instalado..."
LIGUETALK_PATH=$(find "$USER_HOME/.wine/drive_c" -type f -iname "LigueTalk.exe" | head -n 1)

if [ -z "$LIGUETALK_PATH" ]; then
  echo "❌ Erro: Não foi possível localizar o LigueTalk.exe."
  exit 1
fi

# Criar script de execução local
WRAPPER_PATH="$USER_HOME/.local/bin/liguetalk"
mkdir -p "$(dirname "$WRAPPER_PATH")"

echo "Criando script de execução em: $WRAPPER_PATH"
cat <<EOF > "$WRAPPER_PATH"
#!/bin/bash
wine "$LIGUETALK_PATH"
EOF

chmod +x "$WRAPPER_PATH"

# Criar atalho .desktop local
DESKTOP_FILE="$HOME/.local/share/applications/liguetalk.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

echo "Criando atalho no menu de aplicativos em: $DESKTOP_FILE"
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=LigueTalk
Exec=$WRAPPER_PATH
Type=Application
StartupNotify=true
Path=$USER_HOME
Icon=wine
Categories=Network;Application;
EOF

echo "✅ LigueTalk instalado com sucesso!"
echo "Abra o menu de aplicativos e procure por 'LigueTalk' ou execute: liguetalk"
