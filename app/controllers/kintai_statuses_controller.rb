class KintaiStatusesController < ApplicationController
  def create
    logger
    login_mac_address_list = posted_params[:mac_address_list].split(',')

    kintai_service = KintaiService.new(login_mac_address_list)
    kintai_service.execute_jobcan
    kintai_service.reset_login_flg

    render json: { 'text' => '正常に受け取りました' }, stasus: 200
  end

  private

  def posted_params
    params.permit(:mac_address_list, :mac_address_and_maker_list)
  end

  def logger
    Rails.logger.info posted_params[:mac_address_list].split(',')
    Rails.logger.info posted_params[:mac_address_and_maker_list].split(',')
  end
end
