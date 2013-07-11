class GroupRequestsController < BaseController
  before_filter :authenticate_user!, except: [:create, :confirmation, :selection, :subscription, :pwyc]
  before_filter :load_initialize, only: [:subscription, :pwyc]

  def create
    @group_request = GroupRequest.new(params[:group_request])
    if @group_request.save
      @setup_group = SetupGroup.new(@group_request)
      @setup_group.approve_group_request
      redirect_to group_request_confirmation_url
    else
      render 'subscription'
    end
  end

  def confirmation
  end

  def selection
  end

  def subscription
  end

  def pwyc
  end

  private

  def load_initialize
    @group_request = GroupRequest.new
    if user_signed_in?
      @group_request.admin_name = current_user.name
      @group_request.admin_email = current_user.email
    end
  end

end
