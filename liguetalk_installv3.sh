
#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$(id -u)" -eq 0 ]; then
    echo "Erro: Não execute este script como root. Por favor, execute-o como usuário comum."
    exit 1
fi

# Atualizar pacotes e dependências
sudo apt update
sudo apt upgrade -y

# Verificar se o wget está instalado, se não, instalar
if ! command -v wget &> /dev/null; then
    echo "wget não encontrado. Instalando..."
    sudo apt install wget -y
fi

# Adicionar arquitetura i386 (necessária para instalar Wine 32 bits)
sudo dpkg --add-architecture i386

# Atualizar pacotes após adicionar a nova arquitetura
sudo apt update

# Instalar Wine
sudo apt install wine64 wine32 -y

# Verificar se o Wine foi instalado corretamente
if ! command -v wine &> /dev/null; then
    echo "Erro: Wine não foi instalado corretamente."
    exit 1
fi

# Criar diretório para Downloads, caso não exista
mkdir -p ~/Downloads

# Baixar o LigueTalk
wget https://www.microsip.org/download/private/LigueTalk-3.20.7.exe -O ~/Downloads/LigueTalk-3.20.7.exe

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

# Detectar o caminho da área de trabalho do usuário comum
DESKTOP_PATH=$(xdg-user-dir DESKTOP)

# Verificar se a área de trabalho foi encontrada
if [ -z "$DESKTOP_PATH" ]; then
    echo "Erro: Não foi possível localizar o diretório da área de trabalho."
    exit 1
fi

# Mover o script para a área de trabalho do usuário comum
mv ~/abrir_liguetalk.sh "$DESKTOP_PATH/abrir_liguetalk.sh"

echo "Instalação concluída. O atalho para o LigueTalk foi movido para a área de trabalho."
