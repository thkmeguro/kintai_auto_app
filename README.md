# README
- Rails 6.0.2.1
- Ruby 2.7.0

## Docker使用

## （初回）DBを作る
```
$ docker-compose exec db bash
$ psql -U user_name -W password
# CREATE DATABASE webapi_development;
#=> CREATE DATABASE
# CREATE DATABASE webapi_test;
#=> CREATE DATABASE
# \l
#=> 一覧でかくにん
```

## Schemaはridgepoleで管理
## lib/tasks/以下にタスクとして格納、都度Schema変更に際して実行する
```
$ rails db:apply:webapi_development
$ rails db:apply:webapi_development:dry_run
```
## テストはrspecを使用

## ローカル：DockerでRSpecやrails consoleを叩くときはspringを使う
```
# 2回目以降の起動は高速
$ bin/rspec
$ bin/rails c
```

## (あとで) Ruby 2.7 -> 3.0 に向けてのWarning有り

## 不具合解消
### 1 yarnが原因でdocker-compose runが実行できないとき
```
  check_yarn_integrity: true -> false
```
https://qiita.com/KenAra/items/2708ce3d5c80c4f24920

### 2 pumaが上手く起動しない
```
# 以下2つのディレクトリを作成する。

$ mkdir tmp/sockets
$ mkdir tmp/pids
```
https://qiita.com/Esfahan/items/489677a673e9c200686b