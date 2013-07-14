class DiscussionsController < GroupBaseController
  load_and_authorize_resource :except => [:new, :create, :index]
  before_filter :authenticate_user!, :except => [:show, :index]

  rescue_from ActiveRecord::RecordNotFound do
    render 'application/display_error', locals: { message: t('error.not_found') }
  end

  def new
    @discussion = Discussion.new
    @uses_markdown = current_user.uses_markdown
    if params[:group_id]
      @discussion.group_id = params[:group_id]
    else
      @user_groups = current_user.groups.order('name') unless params[:group_id]
    end
  end

  def create
    current_user.update_attributes(uses_markdown: params[:discussion][:uses_markdown])
    @discussion = current_user.authored_discussions.new(params[:discussion])
    authorize! :create, @discussion
    if @discussion.save
      flash[:success] = t("success.discussion_created")
      redirect_to @discussion
    else
      render action: :new
      flash[:error] = t("error.discussion_not_created")
    end
  end

  def destroy
    @discussion.delayed_destroy
    flash[:success] = t("success.discussion_deleted")
    redirect_to @discussion.group
  end

  def index
    if params[:group_id].present?
      @group = Group.find(params[:group_id])
      if cannot? :show, @group
        head 401
      else
        @discussions = Queries::VisibleDiscussions.new(group: @group, user: current_user, subgroups: true).page(params[:page]).per(10)
        render :layout => false if request.xhr?
      end
    else
      authenticate_user!
      @discussions = Queries::VisibleDiscussions.new(user: current_user, subgroups: true).
                     without_current_motions.
                     page(params[:page]).per(10)
      render :layout => false if request.xhr?
    end
  end

  def show
    #@last_collaborator = User.find(@discussion.originator) if @discussion.has_previous_versions?
    @group = GroupDecorator.new(@discussion.group)
    @vote = Vote.new
    @current_motion = @discussion.current_motion
    # can we take this first call out?
    @activity = @discussion.activity
    @filtered_activity = @discussion.filtered_activity
    assign_meta_data
    if params[:proposal]
      @displayed_motion = Motion.find(params[:proposal])
    elsif @current_motion
      @displayed_motion = @current_motion
    end
    if current_user
      @destination_groups = DiscussionMover.destination_groups(@discussion.group, current_user)
      @uses_markdown = current_user.uses_markdown?
      ViewLogger.motion_viewed(@current_motion, current_user) if @current_motion
      @discussion.as_read_by(current_user).viewed!
    end
  end

  def move
    origin = @discussion.group
    destination = Group.find(params[:discussion][:group_id])
    @discussion.group_id = params[:discussion][:group_id]
    if DiscussionMover.can_move?(current_user, origin, destination) && 
      @discussion.save!
      flash[:success] = "Discussion successfully moved."
    else
      flash[:error] = "Discussion could not be moved."
    end
    redirect_to @discussion
  end

  def add_comment
    if params[:comment].present?
      @comment = @discussion.add_comment(current_user, params[:comment], params[:uses_markdown])
      @discussion.as_read_by(current_user).viewed!
      unless request.xhr?
        redirect_to @discussion
      end
    else
      head :ok
    end
  end

  def new_proposal
    discussion = Discussion.find(params[:id])
    if discussion.current_motion
      redirect_to discussion
      flash[:notice] = "A current proposal already exists for this disscussion."
    else
      @motion = Motion.new
      @motion.set_default_close_at_date_and_time
      @motion.discussion = discussion
      @group = GroupDecorator.new(discussion.group)
      render 'motions/new'
    end
  end

  def update_description
    @discussion = Discussion.find(params[:id])
    @discussion.set_description!(params[:description], params[:description_uses_markdown], current_user)
    redirect_to @discussion
  end

  def edit_title
    @discussion = Discussion.find(params[:id])
    @discussion.set_title!(params[:title], current_user)
    redirect_to @discussion
  end

  def show_description_history
    @discussion = Discussion.find(params[:id])
    @originator = User.find @discussion.originator.to_i
    respond_to do |format|
      format.js
    end
  end

  def preview_version
    # assign live item if no version_id is passed
    if params[:version_id].nil?
      @discussion = Discussion.find(params[:id])
    else
      version = Version.find(params[:version_id])
      @discussion = version.reify
    end
    @originator = User.find @discussion.originator.to_i
    respond_to do |format|
      format.js { render :action => 'show_description_history' }
    end
  end

  def update_version
    @version = Version.find(params[:version_id])
    @version.reify.save!
    redirect_to @version.reify()
  end

  private

  def assign_meta_data
    if @group.viewable_by == 'everyone'
      @meta_title = @discussion.title
      @meta_description = @discussion.description
    end
  end

  def group
    @group ||= find_group
  end

  def find_group
    if (params[:id] && (params[:id] != "new"))
      Discussion.find(params[:id]).group
    elsif params[:discussion][:group_id]
      Group.find(params[:discussion][:group_id])
    end
  end
end
