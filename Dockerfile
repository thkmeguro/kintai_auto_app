FROM ruby:2.7.0

# リポジトリを更新し依存モジュールをインストール
RUN set -eu && \
    apt-get update -qq && \
    apt-get install -y build-essential \
                       nodejs \
                       vim
# View含めたRails6の場合webpackerを使用するためyarnが必要
RUN set -eu && \
    apt-get update && apt-get install -y curl apt-transport-https wget && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# spring使うときにdotenvを導入した
RUN set -eu && \
    curl -sfL https://direnv.net/install.sh | bash && \
    echo eval "$(direnv hook bash)" >> ~/.bashrc

# cronを使うためローカルタイムを接待する
ENV TZ Asia/Tokyo

# ルート直下にwebapiという名前で作業ディレクトリを作成（コンテナ内のアプリケーションディレクトリ）
RUN mkdir /webapi
WORKDIR /webapi

# ホストのGemfileとGemfile.lockをコンテナにコピー
ADD Gemfile /webapi/Gemfile
ADD Gemfile.lock /webapi/Gemfile.lock

# bundle installの実行
RUN bundle install

# ホストのアプリケーションディレクトリ内をすべてコンテナにコピー
ADD . /webapi

# puma.sockを配置するディレクトリを作成
RUN mkdir -p tmp/sockets
