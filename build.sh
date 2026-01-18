#!/usr/bin/env bash

mkdir tmp

# Install appimagetool binary
wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool

# Download and uncompress the Oracle JAVA JRE
JRE_URL=$(wget https://www.java.com/pt-br/download/manual.jsp -O- 2>/dev/null | grep ">Linux x64<" | grep -o 'href="[^"]*"' | cut -d '"' -f 2)
mkdir tmp/java
wget $JRE_URL -O- | tar -xz -C tmp/java --strip-components=1

#  Download and extract portable Zenity (GTK3 AppImage)
ZENITY_APPIMAGE_URL="https://github.com/pkgforge-dev/Zenity-GTK3-AppImage/releases/download/continuous/Zenity-3.44-x86_64.AppImage"

wget -c "$ZENITY_APPIMAGE_URL" -O zenity.AppImage
chmod a+x zenity.AppImage

# Extract it into tmp/zenity  (most important files are in usr/)
mkdir -p tmp/zenity
./zenity.AppImage --appimage-extract >/dev/null
mv squashfs-root/* tmp/zenity/ 2>/dev/null || true
rm -rf squashfs-root zenity.AppImage

cp rhe.png tmp

cat <<EOF >tmp/rhe.desktop
[Desktop Entry]
Name=RHE
Icon=rhe
Type=Application
Categories=Office;
EOF

cat <<EOF >tmp/AppRun
#!/usr/bin/env bash

PATH=\$PATH:\$APPDIR/java/bin

(
  # Start of a subshell to pipe all output to zenity
  echo "# Verificando conexão com a internet"
  sleep .5
  if [[ "\$(ping google.com -c1 -w1 -W1 >/dev/null; echo \$?)" == "0" ]]; then
    echo "33"
  else
    echo "100"
    \$APPDIR/zenity/AppRun --info --text="Sem conexão com a internet"
    exit 1
  fi

  echo "# Verificando conexão com a PROCERGS"
  sleep .5
  if [[ "\$(ping cbm.intra.rs.gov.br -c1 -w1 -W1 &>/dev/null; echo \$?)" == "0" ]]; then
    echo "66"
  else
    echo "100"
    \$APPDIR/zenity/AppRun  --info --text="Sem conexão com a rede PROCERGS"
    exit 1
  fi

  echo "# Checando a disponibilidade do código JAVA (JNLP)"
  sleep .5
  if [[ "\$(curl https://secweb.intra.rs.gov.br/forms/frmservlet?config=rhep &>/dev/null; echo \$?)" == "0" ]]; then
    echo "100"
    javaws https://secweb.intra.rs.gov.br/forms/frmservlet?config=rhep
  else
    echo "100"
    \$APPDIR/zenity/AppRun  --info --text="Não é possível acessar o servidor do RHE"
    exit 1
  fi

) | \$APPDIR/zenity/AppRun  --progress \
  --title="Verificando a conexão" \
  --text="iniciando..." \
  --percentage=0 \
  --auto-close \
  --no-cancel
EOF
chmod a+x tmp/AppRun
./appimagetool tmp

rm appimagetool
rm -rf tmp/
