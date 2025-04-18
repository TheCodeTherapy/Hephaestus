final: prev: {
  brave = prev.stdenv.mkDerivation {
    pname = "brave";
    version = prev.brave.version;

    nativeBuildInputs = [ prev.makeWrapper ];

    buildCommand = ''
      mkdir -p $out/bin
      mkdir -p $out/share/applications
      mkdir -p $out/share/icons/hicolor/256x256/apps

      # Wrap the original brave binary with the desired flags
      makeWrapper ${prev.brave}/bin/brave $out/bin/brave \
        --add-flags "--password-store=basic"

      # Desktop entry that uses the wrapped binary
      cat > $out/share/applications/brave-browser.desktop <<EOF
      [Desktop Entry]
      Version=1.0
      Name=Brave Browser
      GenericName=Web Browser
      Comment=Access the Internet
      Exec=$out/bin/brave %U
      Terminal=false
      Type=Application
      Icon=brave-browser
      Categories=Network;WebBrowser;
      MimeType=x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
      EOF

      # Try to preserve the icon from the original package
      icon_src="${prev.brave}/share/icons/hicolor/256x256/apps/brave-browser.png"
      if [ -f "$icon_src" ]; then
        cp "$icon_src" $out/share/icons/hicolor/256x256/apps/brave-browser.png
      fi
    '';
  };
}
