# README

## Schemaはridgepoleで管理している
## lib/tasks/以下にタスクとして格納している
```
$ bundle exec rails db:apply:webapi_development
$ bundle exec rails db:apply:webapi_development:dry_run
```
## テストはrspecを使用している
## Dockerを使用している
## ローカル：DockerでRSpecやrails consoleを叩くときはspringを使う
```
# 2回目以降の起動は高速
# dotenvを入れているのでbin/は不要かも
$ bin/rspec
$ bin/rails c
```

## ruby2.7特有のエラーは出ているが今は消していない