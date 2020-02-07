# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

require 'dotenv'
namespace :db do
  desc 'スキーマを更新する'
  namespace :apply do
    task :update, [:database_name] do |_, db_name|
      raise StandardError, '存在しないDBです' unless db_name == ('webapi_development' || 'webapi')
      Dotenv.load
      ENV['ALLOW_DROP_TABLE'] ||= '0'
      ENV['ALLOW_REMOVE_COLUMN'] ||= '0'
      ENV['DATABASE_ENV'] ||= 'development'

      task_return = `bundle exec ridgepole -E #{ENV['DATABASE_ENV']} --diff database.yml Schemafile`

      column_condition = task_return.include?('remove_column') && ENV['ALLOW_REMOVE_COLUMN'] == '0'
      table_condition = task_return.include?('drop_table') && ENV['ALLOW_DROP_TABLE'] == '0'

      if column_condition || table_condition
        puts "\x1b[31mカラムを削除しますか？その場合は ALLOW_REMOVE_COLUMN=1 を指定してください\x1b[0m" if column_condition
        puts "\x1b[31mテーブルを削除しますか？その場合は ALLOW_DROP_TABLE=1 を指定してください\x1b[0m" if table_condition
      else
        sh "bundle exec ridgepole -E #{ENV['DATABASE_ENV']} -c ./config/database.yml -f ./config/Schemafile -a --debug"
      end
    end

    task :webapi_development do
      Rake::Task['db:apply:update'].execute('webapi_development')
    end

    task :webapi do
      Rake::Task['db:apply:update'].execute('webapi')
    end

    namespace :webapi_development do
      task :dry_run do
        Dotenv.load
        ENV['DATABASE_ENV'] ||= 'development'
        sh "bundle exec ridgepole -E #{ENV['DATABASE_ENV']} -c ./config/database.yml -f ./config/Schemafile -a --debug --dry-run"
      end
    end
  end
end