FROM nginx:1.17.8

# インクルード用のディレクトリ内を削除
# なしだと以下default.confが立ち上がってconflictする
# /etc/nginx/conf.d/default.conf:    server_name  localhost;
RUN rm -f /etc/nginx/conf.d/*

# Nginxの設定ファイルをコンテナにコピー
ADD nginx.conf /etc/nginx/conf.d/webapi.conf

# ビルド完了後にNginxを起動
CMD /usr/sbin/nginx -g 'daemon off;' -c /etc/nginx/nginx.conf
