ActiveAdmin.register GroupRequest do
  actions :all, :except => [:new]
  scope :waiting, :default => true
  scope :starred
  scope :unverified
  scope :zero_members
  scope :approved_but_not_setup
  scope :setup_completed
  scope :all

  filter :name
  filter :description
  filter :admin_email
  filter :admin_name
  filter :high_touch

  index do
    column :id
    column :name_and_contact do |gr|
      name = ERB::Util.h(gr.name)
      admin_name = ERB::Util.h(gr.admin_name)
      admin_email = ERB::Util.h(gr.admin_email)
      (link_to(name, edit_admin_group_request_path(gr)) +
       "<br><br>#{admin_name}".html_safe +
       " &lt;#{admin_email}&gt;".html_safe)
    end
    column :description
    column :admin_notes
    column 'Size', :expected_size
    column 'Subscription' do |gr|
      gr.cannot_contribute? == false
    end
    column :created_at, sortable: :created_at do |gr|
      gr.created_at.to_date
    end
    column :status
    column :actions do |gr|
      span do
        links = []
        unless gr.approved?
          links << link_to('Approve', approve_and_send_form_admin_group_request_path(gr))
        end
        links << link_to('Star', set_high_touch_admin_group_request_path(gr), :method => :put) unless gr.high_touch?
        links << link_to('Un-star', unset_high_touch_admin_group_request_path(gr), :method => :put) if gr.high_touch?
        links << link_to('Edit', edit_admin_group_request_path(gr))
        links << link_to('Destroy', admin_group_request_path(gr), method: :delete,
          data: { confirm: "Are you sure you want to delete the request?" })
        links.join(' ').html_safe
      end
    end
  end

  form partial: 'form'

  member_action :set_high_touch, :method => :put do
    @group_request = GroupRequest.find(params[:id])
    @group_request.update_attribute(:high_touch, true)
    redirect_to admin_group_requests_path
  end

  member_action :unset_high_touch, :method => :put do
    @group_request = GroupRequest.find(params[:id])
    @group_request.update_attribute(:high_touch, false)
    redirect_to admin_group_requests_path
  end

  member_action :approve_and_send_form, :method => :get do
    @group_request = GroupRequest.find(params[:id])
  end

  member_action :approve_and_send, :method => :put do
    @group_request = GroupRequest.find(params[:id])
    @group_request.update_attribute(:max_size, params[:group_request][:max_size])

    setup_group = SetupGroup.new(@group_request)
    group = setup_group.approve_group_request(approved_by: current_user)
    setup_group.send_invitation_to_start_group(inviter: current_user, message_body: params[:message_body])
    redirect_to admin_group_requests_path,
      :notice => ("Group approved: " +
      "<a href='#{admin_group_path(group)}'>#{group.name}</a>").html_safe
  end

  member_action :update, method: :put do
    update! do |format|
      format.html {redirect_to admin_group_requests_path}
    end
  end

  member_action :defer_and_send_form, :method => :get do
    @group_request = GroupRequest.find(params[:id])
  end

  member_action :defer_and_save, :method => :put do
    @group_request = GroupRequest.find(params[:id])
    @group_request.defered_until = params[:group_request][:defered_until]
    @group_request.save!
    @group_request.defer!
    StartGroupMailer.defered(@group_request).deliver
    redirect_to admin_group_requests_path, :notice => "Group request defered."
  end

  member_action :mark_as_manually_approved, :method => :put do
    group_request = GroupRequest.find(params[:id])
    group_request.mark_as_manually_approved!
    redirect_to admin_group_requests_path,
      :notice => "Group marked as 'already approved': " +
      group_request.name
  end

  member_action :mark_as_spam, :method => :put do
    group_request = GroupRequest.find(params[:id])
    group_request.mark_as_spam!
    redirect_to admin_group_requests_path,
      :notice => "Group marked as 'spam': " +
      group_request.name
  end

  member_action :mark_as_verified, :method => :put do
    group_request = GroupRequest.find(params[:id])
    group_request.verify!
    redirect_to admin_group_requests_path,
      :notice => "Group returned to 'verified': " +
      group_request.name
  end

  member_action :mark_as_unverified, :method => :put do
    group_request = GroupRequest.find(params[:id])
    group_request.mark_as_unverified!
    redirect_to admin_group_requests_path,
      :notice => "Group marked as 'unverified': " +
      group_request.name
  end

  member_action :resend_verification, :method => :get do
    group_request = GroupRequest.find(params[:id])
    StartGroupMailer.verification(group_request).deliver
    redirect_to admin_group_requests_path,
      :notice => "Verification email sent for " +
      group_request.name
  end

  member_action :resend_invitation_to_start_group, :method => :get do
    group_request = GroupRequest.find(params[:id])
    group_request.send_invitation_to_start_group
    redirect_to admin_group_requests_path,
      :notice => "Invitation to start group email sent for " +
      group_request.name
  end

end
