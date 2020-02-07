class SlacksController < ApplicationController
  def show

  end

  def create
    log_url        = ENV.fetch("SLACK_LOG_POST_URL") {}
    header_options = { 'Content-type' => 'application/json' }

    data = {'text' => "#{params}"}.to_json
    Io::Api.new.request_api(log_url, data, header_options)

    data = params
    type = data['type']
    callback_id = params['callback_id']

    if type === 'dialog_submission'
      dialog_from = callback_id.split(':')[0] # ex: create_user_data

      case dialog_from
      when 'create_user_data'
        create_user_data_by_dialog(data)
        render json: {'text' => '自動打刻設定を登録しました！'}, stasus: 200
      end
    else
      trigger_id   = params['trigger_id']
      response_url = params['response_url']

      case callback_id
      when 'create_user_setting'
        create_menu_data(response_url, trigger_id)
        render json: {'text' => 'ダイアログを開きます'}, stasus: 200
      when 'show_user_setting'
        render json: { 'text' => "#{data}" }, stasus: 200
      when 'disable_user_setting'
        render json: { 'text' => "#{data}" }, stasus: 200
      when 'enable_user_setting'
        render json: { 'text' => "#{data}" }, stasus: 200
      else
        render json: { 'text' => "キャンセルしました" }, stasus: 200
      end
    end
  end

  private

  def create_user_data_by_dialog(data)
    user_id, user_name = '', ''
    user_id, user_name = data['user']['id'], data['user']['name'] if data['user']

    Member.find_or_create_by(user_id: user_id, user_name: user_name)

    mac_address_list = {
        pc_macaddress:         data['submission']['pc_macaddress'],
        smartphone_macaddress: data['submission']['smartphone_macaddress'],
        tablet_macaddress:     data['submission']['tablet_macaddress'],
        other_macaddress:      data['submission']['other_macaddress']
    }

    Device.where(user_id: user_id).map{|r| r.update!({deleted: 1})}

    mac_address_list.each do |device_type, mac_address|
      next if mac_address
      device = Device.find_or_initialize_by(user_id: user_id, mac_address: mac_address)
      device.update!({device_type: device_type, deleted: 0})
    end
  end

  def create_menu_data(response_url, trigger_id)
    header_options = {'Content-type' => 'application/json'}
    callback_id    = "create_user_data:#{Time.current.to_i}" # slackからdialogの返答とともに返送されてくるのでvalidationできる
    data = {
        'trigger_id' => trigger_id,
        'dialog' => {
            'callback_id' => callback_id,
            'title' => '自動打刻設定の登録',
            'submit_label' => '登録する',
            'notify_on_cancel' => true,
            'state' => '普段ホームに持ち込む機器を登録してください！',
            'elements' => [
                {
                    'type'        => 'text',
                    'max_length'  => 17,
                    'min_length'  => 17,
                    'placeholder' => '22:33:00:aa',
                    'optional'    => false,
                    'label'       => 'PCのMAC Address',
                    'name'        => 'pc_macaddress'
                },
                {
                    'type'        => 'text',
                    'max_length'  => 17,
                    'min_length'  => 17,
                    'placeholder' => 'a2:3v:00:aa',
                    'optional'    => false,
                    'label'       => 'スマートフォンのMAC Address',
                    'name'        => 'smartphone_macaddress'
                },
                {
                    'type'        => 'text',
                    'max_length'  => 17,
                    'min_length'  => 17,
                    'placeholder' => 'm2:73:50:9a',
                    'optional'    => true ,
                    'label'       => 'タブレットのMAC Address',
                    'name'        => 'tablet_macaddress'
                },
                {
                    'type'        => 'text',
                    'max_length'  => 17,
                    'min_length'  => 17,
                    'placeholder' => '19:dr:10:nm',
                    'optional'    => true,
                    'label'       => 'その他機器のMAC Address',
                    'name'        => 'other_macaddress'
                }
            ]
        }
    }.to_json
    Io::Api.new.request_api(response_url, data, header_options)
  end
end
