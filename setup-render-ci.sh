sudo apt-get install -y inkscape
quarto install chromium
mkdir -p ~/.local/bin
~/.TinyTeX/bin/x86_64-linux/tlmgr option sys_bin ~/.local/bin
~/.TinyTeX/bin/x86_64-linux/tlmgr path add
~/.TinyTeX/bin/x86_64-linux/tlmgr update --self