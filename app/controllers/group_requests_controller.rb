class GroupRequestsController < BaseController
  before_filter :authenticate_user!, except: [:create, :confirmation, :selection, :subscription, :pwyc]
  before_filter :load_initialize, only: [:subscription, :pwyc]

  def create
    @group_request = GroupRequest.new(params[:group_request])
    @group_request.paying_subscription
    if @group_request.save
      @setup_group = SetupGroup.new(@group_request)
      @setup_group.setup(@group_request.paying_subscription)
      redirect_to confirmation_group_requests_url
    else
      if @group_request.paying_subscription == true
        render 'subscription', submit_label: "Start your free trial!"
      else
        render 'pwyc', submit_label: "Start group!"
      end
    end
  end

  def confirmation
  end

  def selection
  end

  def subscription
    @group_request.paying_subscription = true
  end

  def pwyc
    @group_request.paying_subscription = false
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
