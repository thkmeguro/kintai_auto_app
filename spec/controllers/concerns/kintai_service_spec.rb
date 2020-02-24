# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KintaiService, type: :concern do
  describe 'publicメソッドが正常に機能すること' do
    describe '#execute_jobcan' do
      context 'ログインしていないメンバーの場合' do
        let!(:member_not_login) { create(:member) }
        let!(:device_1) { create(:device) }

        it '打刻とフラグ変えが行われること' do
          slack_client_latest_mock = double('slack client mock')
          slack_client_legacy_mock = double('slack client mock')
          expect(slack_client_latest_mock).to receive(:is_user_id_valid?).and_return(true)
          expect(slack_client_legacy_mock).to receive(:check_and_post_work_status).and_return(true)
          expect(slack_client_latest_mock).to receive(:fetch_todays_jobcan_mss).and_return({is_working: true, time: Time.now})
          expect(slack_client_legacy_mock).to receive(:kintai_start_when_not).and_return(true)

          dummy_mac_address_list = %w(aa:bb:cc:dd:ee:11 aa:bb:cc:dd:ee:12)
          kintai_service = KintaiService.new(dummy_mac_address_list)
          remove_list = ['']
          stub_const("KintaiService", remove_list)
          expect(KintaiService::REMOVE_LIST).to eq(remove_list)

          expect(kintai_service.execute_jobcan)
              .to receive(:slack_client).and_return(slack_client_latest_mock, slack_client_legacy_mock)
              .to change(member_not_login.has_connected_today).to(1)
              .and change(member_not_login.slack_legacy_token).eq(member_not_login.slack_legacy_token)
              .and change(member_not_login.slack_authed_user_access_token).eq(member_not_login.slack_authed_user_access_token)
        end
      end

      context 'ログインしたメンバーの場合' do
        it '処理はスルーされること' do
        end
      end

      context '失敗し例外が出た場合' do
        it '後続の処理が続くこと' do
        end
      end
    end

    describe '#reset_login_flg' do
      context 'フラグをリセットする時間だった場合' do
        it 'フラグがリセットされること' do
        end
      end

      context 'フラグをリセットしない時間だった場合' do
        it 'フラグがリセットされないこと' do
        end
      end
    end
  end
end
