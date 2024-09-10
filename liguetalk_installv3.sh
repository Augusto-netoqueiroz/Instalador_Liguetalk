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

# Identificar o usuário que está rodando o script
USER_HOME=$(eval echo ~$(logname))

# Verificar se a pasta do usuário foi identificada
if [ -z "$USER_HOME" ]; then
    echo "Erro: Não foi possível identificar a pasta home do usuário."
    exit 1
fi

# Criar script para abrir o LigueTalk no diretório correto do usuário
echo '#!/bin/bash' > "$USER_HOME/abrir_liguetalk.sh"
echo "wine '$LIGUETALK_PATH'" >> "$USER_HOME/abrir_liguetalk.sh"

# Tornar o script executável
chmod +x "$USER_HOME/abrir_liguetalk.sh"

# Criar arquivo .desktop na pasta home do usuário
cat <<EOF > "$USER_HOME/LigueTalk.desktop"
[Desktop Entry]
Version=1.0
Name=LigueTalk
Comment=Executar o LigueTalk via Wine
Exec=$USER_HOME/abrir_liguetalk.sh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Application
EOF

# Tornar o arquivo .desktop executável
chmod +x "$USER_HOME/LigueTalk.desktop"

# Verificar se o script foi criado corretamente
if [ -f "$USER_HOME/abrir_liguetalk.sh" ]; then
    echo "Script abrir_liguetalk.sh criado em $USER_HOME."
else
    echo "Erro: Não foi possível criar o script abrir_liguetalk.sh."
fi

# Verificar se o atalho foi criado com sucesso
if [ -f "$USER_HOME/LigueTalk.desktop" ]; then
    echo "Atalho criado na pasta home do usuário $USER_HOME."
else
    echo "Erro: Não foi possível criar o atalho na pasta home do usuário."
fi

echo "Instalação concluída."
