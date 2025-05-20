#!/bin/bash

# Parar o script em caso de erro
set -e

# Definir usuário real e home dele
REAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo "~$REAL_USER")

# Verifica se Wine está instalado
if ! command -v wine &> /dev/null; then
  echo "Instalando Wine..."
  sudo dpkg --add-architecture i386
  sudo apt update
  sudo apt install wine64 wine32 wine wine32-preloader wine64-preloader -y
fi

# Inicializar Wine para o usuário real (cria ~/.wine)
echo "Inicializando Wine para o usuário $REAL_USER..."
sudo -u "$REAL_USER" winecfg &>/dev/null || true

# Caminho para download e instalação
INSTALLER_NAME="LigueTalk-3.20.7.exe"
INSTALLER_URL="https://www.microsip.org/download/private/$INSTALLER_NAME"
INSTALLER_PATH="$USER_HOME/Downloads/$INSTALLER_NAME"

# Baixar instalador se não existir
if [ ! -f "$INSTALLER_PATH" ]; then
  echo "Baixando instalador do LigueTalk..."
  sudo -u "$REAL_USER" wget -O "$INSTALLER_PATH" "$INSTALLER_URL"
fi

# Executar instalador como o usuário real
echo "Executando o instalador do LigueTalk com Wine..."
sudo -u "$REAL_USER" wine "$INSTALLER_PATH"

# Procurar caminho do executável instalado
echo "Procurando caminho do LigueTalk instalado..."
LIGUETALK_PATH=$(sudo -u "$REAL_USER" find "$USER_HOME/.wine/drive_c" -type f -iname "LigueTalk.exe" | head -n 1)

if [ -z "$LIGUETALK_PATH" ]; then
  echo "❌ Erro: Não foi possível localizar o LigueTalk.exe."
  exit 1
fi

# Criar script de execução
WRAPPER_PATH="/usr/local/bin/liguetalk"
echo "Criando script de execução em: $WRAPPER_PATH"
cat <<EOF | sudo tee "$WRAPPER_PATH" > /dev/null
#!/bin/bash
sudo -u "$REAL_USER" wine "$LIGUETALK_PATH"
EOF

sudo chmod +x "$WRAPPER_PATH"

# Criar atalho .desktop para todos os usuários
DESKTOP_FILE="/usr/share/applications/liguetalk.desktop"
echo "Criando atalho no menu de aplicativos em: $DESKTOP_FILE"
cat <<EOF | sudo tee "$DESKTOP_FILE" > /dev/null
[Desktop Entry]
Name=LigueTalk
Exec=$WRAPPER_PATH
Type=Application
StartupNotify=true
Path=$USER_HOME
Icon=wine
Categories=Network;Application;
EOF

echo "✅ Instalação do LigueTalk concluída com sucesso!"
