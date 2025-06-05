#!/bin/bash

# Parar o script em caso de erro
set -e

# Esta variável indica o diretório HOME do usuário que chamou o script
USER_HOME="$HOME"

# Função: verifica se a arquitetura i386 já está habilitada
verificar_e_habilitar_i386() {
  # dpkg --print-foreign-architectures lista as arquiteturas habilitadas além de amd64
  if dpkg --print-foreign-architectures | grep -qx "i386"; then
    echo "✔ Arquitetura i386 já habilitada."
  else
    echo "🔄 Habilitando arquitetura i386..."
    sudo dpkg --add-architecture i386
    echo "✔ i386 adicionado. Atualizando lista de pacotes..."
    sudo apt-get update -y
  fi
}

# Função: instala o WineHQ (stable) no Ubuntu Jammy/22.04
instalar_wine_jammy() {
  echo "🚧 Wine não encontrado. Instalando WineHQ (stable) para Ubuntu Jammy..."

  # 1) Verificar e habilitar i386
  verificar_e_habilitar_i386

  # 2) Instalar dependências básicas para adicionar o repositório
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends software-properties-common wget gnupg2

  # 3) Importar chave do WineHQ e adicionar o repositório oficial
  wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
  sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -sc) main"
  sudo apt-get update -y

  # 4) Instalar o pacote winehq-stable (traz as dependências i386 e amd64)
  sudo apt-get install -y --install-recommends winehq-stable

  echo "✅ WineHQ instalado com sucesso."
}

# Verifica se o comando `wine` existe
if ! command -v wine &> /dev/null; then
  instalar_wine_jammy
fi

# Se o Wine já existia, ainda precisamos garantir que a arquitetura i386 está habilitada
# (caso alguém tenha instalado Wine de outra forma e não habilitou i386)
verificar_e_habilitar_i386

# Inicializar prefixo do Wine (vai criar ~/.wine se não existir)
echo "🔄 Inicializando prefixo do Wine (se for a primeira vez)…"
winecfg &>/dev/null || true

# Configurações do instalador LigueTalk
INSTALLER_NAME="LigueTalk-3.20.7.exe"
INSTALLER_URL="https://www.microsip.org/download/private/$INSTALLER_NAME"
INSTALLER_PATH="$USER_HOME/Downloads/$INSTALLER_NAME"

# 1) Baixar instalador se não existir
if [ ! -f "$INSTALLER_PATH" ]; then
  echo "⬇️  Baixando $INSTALLER_NAME para $INSTALLER_PATH…"
  wget -O "$INSTALLER_PATH" "$INSTALLER_URL"
fi

# 2) Executar instalador via Wine
echo "▶️  Executando o instalador $INSTALLER_NAME com Wine…"
wine "$INSTALLER_PATH"

# 3) Procurar o executável instalado "LigueTalk.exe" dentro do prefixo ~/.wine
echo "🔍 Procurando o caminho de instalação do LigueTalk.exe…"
LIGUETALK_PATH=$(find "$USER_HOME/.wine/drive_c" -type f -iname "LigueTalk.exe" | head -n 1)

if [ -z "$LIGUETALK_PATH" ]; then
  echo "❌ Erro: não foi possível localizar o LigueTalk.exe em ~/.wine/drive_c"
  exit 1
fi

# 4) Criar script wrapper em ~/.local/bin para rodar o LigueTalk via Wine
WRAPPER_PATH="$USER_HOME/.local/bin/liguetalk"
mkdir -p "$(dirname "$WRAPPER_PATH")"

echo "✏️  Criando script de execução em: $WRAPPER_PATH"
cat <<EOF > "$WRAPPER_PATH"
#!/bin/bash
wine "$LIGUETALK_PATH"
EOF
chmod +x "$WRAPPER_PATH"

# 5) Criar atalho .desktop em ~/.local/share/applications
DESKTOP_FILE="$USER_HOME/.local/share/applications/liguetalk.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

echo "✏️  Criando atalho no menu de aplicativos em: $DESKTOP_FILE"
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

# Conclusão
echo "✅ LigueTalk instalado com sucesso!"
echo "   → Você pode abrir pelo menu de aplicativos (‘LigueTalk’) ou executando no terminal: liguetalk"
