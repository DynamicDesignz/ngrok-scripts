#!/usr/bin/env bash
copy_tls() {
  echo 'Copy tls...'
  cp cache/tls/rootCA.crt ngrok/assets/client/tls/ngrokroot.crt
  cp cache/tls/server.crt ngrok/assets/server/tls/snakeoil.crt
  cp cache/tls/server.key ngrok/assets/server/tls/snakeoil.key
}

. scripts/get_domain.sh
. scripts/get_port.sh
. scripts/generate_tls.sh

if [ ! -d ngrok ]; then
  git clone https://github.com/weirongxu/ngrok.git --depth 1
fi

if [ ! -d ngrok ]; then
  echo "Clone error!"
  exit
fi

copy_tls

cd ngrok

domain_srt=src/ngrok/client/model.go

cp ${domain_srt} ${domain_srt}.bak

sed -e "s/ngrokd\\.ngrok\\.com:443/$NGROK_DOMAIN:4443/g" ${domain_srt}.bak > ${domain_srt}

echo "$(make release-all)"

rm ${domain_srt}
mv ${domain_srt}.bak ${domain_srt}

cd ..

. scripts/echo_nginx_config.sh

cat > scripts/run.sh <<-EOF
$(pwd)/ngrok/bin/ngrokd -domain="$NGROK_DOMAIN" -httpAddr=":$NGROK_HTTP_PORT" -srcHttpAddr=":80" -httpsAddr=":$NGROK_HTTPS_PORT" -srcHttpsAddr=":433"
EOF

chmod +x scripts/run.sh
