# class Jobcan
#   WORK_STATUS_CHECK_CHANNEL_ID = 'DD7V37Y73' # todo:teamによって変える.これはSORAの個人DM内
#   WORK_STATUS_CHECK_CHANNEL_ID = 'CTKL5S6TH' # todo:teamによって変える.これはMTのプライベートチャンネル
#
#   def initialize(token, slack_authed_user_id)
#     @slack_authed_user_id = slack_authed_user_id
#     Slack.configure { |config| config.token = token }
#     @client = Slack::Web::Client.new
#   end
#
#   # user_infoを確認する
#   def is_user_id_valid?
#     begin
#       @client.users_info(user: @slack_authed_user_id)
#     rescue => e
#       Rails.logger.error e.message
#       false
#     end
#   end
#
#   # 勤怠時間を確認し特定のチャンネルに投稿する
#   # chat_commandはlegacy_tokenで作ったインスタンスでのみ可能
#   def check_work_status
#     # todo ここをjobcanにする
#     # @client.chat_command(channel: WORK_STATUS_CHECK_CHANNEL_ID, command:'/jobcan_worktime')
#     @client.chat_command(channel: WORK_STATUS_CHECK_CHANNEL_ID, command:'/forecast', text: 'helsinki')
#     sleep(3)
#   end
#
#   # check_work_statusと同じチャンネルのメッセージを取得してユーザーごとの勤務状況を調べる
#   def fetch_todays_jobcan_mss
#     # todo:個人のDMで実験するのでim_historyメソッドを使用する
#     # messages = @client.im_history(channel: WORK_STATUS_CHECK_CHANNEL_ID, inclusive: true).messages
#     messages = @client.groups_history(channel: WORK_STATUS_CHECK_CHANNEL_ID, inclusive: true).messages
#
#     messages.map do |i|
#       unix_timestamp = i['ts'].split(/\./)[0] ? i['ts'].split(/\./)[0].to_i : nil
#       next unless unix_timestamp
#
#       time = Time.at(unix_timestamp)
#       next if time < Date.today
#
#       user_id_on_bot = /^\<\@(?<user_id_data>[A-Z|0-9]+)\>/ =~ i['text'] && user_id_data
#       next if user_id_on_bot == @slack_authed_user_id
#
#       is_bot = i['subtype'] == 'bot_message'
#       is_before_work = (/00\:00\(未出勤\)です/ =~ i['text']) && is_bot
#       is_working = (/\d{2}\:\d{2}\(勤務中\)です/ =~ i['text']) && is_bot
#       is_taking_a_break = (/\d{2}\:\d{2}\(退室中\)です/ =~ i['text']) && is_bot
#
#       case
#       when is_working
#         {is_working: true, time: time}
#       when is_before_work || is_taking_a_break
#         {is_working: false, time: time}
#       else
#         nil
#       end
#     end.compact
#   end
#
#   def kintai_start_when_not(statuses)
#     latest_status = statuses.first
#     # todo テストが終わったら発火を制御する(それまでは台北の天気を必ずだす)
#     # latest_status[:is_working] ? nil : jobcan_touch
#     false ? nil : jobcan_touch
#   end
#
#   # 打刻するコマンド
#   # chat_commandはlegacy_tokenで作ったインスタンスでのみ可能
#   def jobcan_touch
#     # todo ここをjobcanにする
#     pp "コメントアウトして無ければ、コマンドが実行される:#{WORK_STATUS_CHECK_CHANNEL_ID}"
#     # @client.chat_command(channel: WORK_STATUS_CHECK_CHANNEL_ID, command:'/jobcan_touch')
#     #
#     @client.chat_command(channel: WORK_STATUS_CHECK_CHANNEL_ID, command:'/forecast', text: 'taipei')
#   end
# end