require 'dotenv'
namespace :db do
  namespace :apply do
    desc 'スキーマ更新を実行する'
    task :update, [:database_name] do |_, db_name|
      Dotenv.load
      ENV['ALLOW_DROP_TABLE'] ||= '0'
      ENV['ALLOW_REMOVE_COLUMN'] ||= '0'
      ENV['RAILS_ENV'] ||= 'development'

      task_return = `bundle exec ridgepole -E #{ENV['RAILS_ENV']} --diff #{Rails.root}/config/database.yml #{Rails.root}/config/Schemafile`

      column_condition = task_return.include?('remove_column') && ENV['ALLOW_REMOVE_COLUMN'] == '0'
      table_condition = task_return.include?('drop_table') && ENV['ALLOW_DROP_TABLE'] == '0'

      if column_condition || table_condition
        puts "\x1b[31mカラムを削除しますか？その場合は ALLOW_REMOVE_COLUMN=1 を指定してください\x1b[0m" if column_condition
        puts "\x1b[31mテーブルを削除しますか？その場合は ALLOW_DROP_TABLE=1 を指定してください\x1b[0m" if table_condition
      else
        sh "bundle exec ridgepole -E #{ENV['RAILS_ENV']} -c #{Rails.root}/config/database.yml -f #{Rails.root}/config/Schemafile -a --debug"
      end
    end

    desc 'テスト環境のスキーマを実行する'
    task :webapi_test do
      Rake::Task['db:apply:update'].execute('webapi_test')
    end

    desc '開発環境のスキーマを実行する'
    task :webapi_development do
      Rake::Task['db:apply:update'].execute('webapi_development')
    end

    desc '本番環境のスキーマを実行する'
    task :webapi do
      Rake::Task['db:apply:update'].execute('webapi')
    end

    namespace :webapi_development do
      task :dry_run do
        Dotenv.load
        ENV['RAILS_ENV'] ||= 'development'
        sh "bundle exec ridgepole -E #{ENV['RAILS_ENV']} -c ./config/database.yml -f ./config/Schemafile -a --debug --dry-run"
      end
    end
  end
end
