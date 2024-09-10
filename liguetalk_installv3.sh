#!/bin/bash

# Adicionar arquitetura i386 (necessária para instalar Wine 32 bits)
sudo dpkg --add-architecture i386

# Atualizar pacotes e dependências
sudo apt update

# Verificar se wget e wine estão instalados, e instalar apenas se necessário
sudo apt install -y wget wine64 wine32

# Verificar se o Wine foi instalado corretamente
if ! command -v wine &> /dev/null; then
    echo "Erro: Wine não foi instalado corretamente."
    exit 1
fi

# Criar diretório para Downloads, caso não exista
mkdir -p ~/Downloads

# Baixar o LigueTalk
if [ ! -f ~/Downloads/LigueTalk-3.20.7.exe ]; then
    wget https://www.microsip.org/download/private/LigueTalk-3.20.7.exe -O ~/Downloads/LigueTalk-3.20.7.exe
fi

# Verificar se o LigueTalk foi baixado corretamente
if [ ! -f ~/Downloads/LigueTalk-3.20.7.exe ]; then
    echo "Erro: Não foi possível baixar o LigueTalk."
    exit 1
fi

# Instalar o LigueTalk usando o Wine
wine ~/Downloads/LigueTalk-3.20.7.exe

# Verificar se o LigueTalk foi instalado corretamente
LIGUETALK_PATH=$(find ~/.wine/ -name LigueTalk.exe 2> /dev/null)

if [ -z "$LIGUETALK_PATH" ]; then
    echo "Erro: LigueTalk não foi encontrado após a instalação."
    exit 1
fi

# Criar script para abrir o LigueTalk
echo '#!/bin/bash' > ~/abrir_liguetalk.sh
echo "wine '$LIGUETALK_PATH'" >> ~/abrir_liguetalk.sh

# Tornar o script executável
chmod +x ~/abrir_liguetalk.sh

# Detectar o caminho da área de trabalho do root e do usuário comum
ROOT_DESKTOP_PATH="/root/Desktop"
USER_DESKTOP_PATH=$(xdg-user-dir DESKTOP)

# Se o diretório da área de trabalho do usuário não for encontrado, usa o diretório padrão da pasta inicial
if [ -z "$USER_DESKTOP_PATH" ]; then
    USER_DESKTOP_PATH=/home/$(whoami)/Desktop
    mkdir -p "$USER_DESKTOP_PATH"
fi

# Criar o atalho na área de trabalho do root, se o script estiver sendo executado como root
if [ "$EUID" -eq 0 ]; then
    # Criar arquivo .desktop para o root
    mkdir -p "$ROOT_DESKTOP_PATH"
    cat <<EOF > "$ROOT_DESKTOP_PATH/LigueTalk.desktop"
[Desktop Entry]
Version=1.0
Name=LigueTalk
Comment=Executar o LigueTalk via Wine
Exec=/root/abrir_liguetalk.sh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Application
EOF
    # Tornar o arquivo .desktop do root executável
    chmod +x "$ROOT_DESKTOP_PATH/LigueTalk.desktop"
fi

# Criar o atalho na área de trabalho do usuário comum
cat <<EOF > "$USER_DESKTOP_PATH/LigueTalk.desktop"
[Desktop Entry]
Version=1.0
Name=LigueTalk
Comment=Executar o LigueTalk via Wine
Exec=/home/$(whoami)/abrir_liguetalk.sh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Application
EOF

# Tornar o arquivo .desktop do usuário comum executável
chmod +x "$USER_DESKTOP_PATH/LigueTalk.desktop"

echo "Instalação concluída. O atalho para o LigueTalk foi criado na área de trabalho."
