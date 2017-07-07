Spree::Admin::UsersController.class_eval do

  def update
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    begin
      if @user.update_attributes(user_params)
        flash.now[:success] = Spree.t(:account_updated)
      end
    rescue Exception => e
      flash.now[:error] =  e.message
    end

    render :edit
  end

  def user_params
    params[:user][:mailchimp_lists_ids] = params[:user][:mailchimp_lists_ids].select{|l| !l.blank? }.to_json if !params[:user][:mailchimp_lists_ids].blank?
    
    params.require(:user).permit(permitted_user_attributes |
                                 [spree_role_ids: [],
                                  ship_address_attributes: permitted_address_attributes,
                                  bill_address_attributes: permitted_address_attributes])
  end
end
