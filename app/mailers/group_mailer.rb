class GroupMailer < BaseMailer
  def new_membership_request(membership)
    @user = membership.user
    @group = membership.group
    @admins = @group.admins
    @group.admins.each do |admin|
      GroupMailer.membership_request(admin, @user, @group).deliver
    end
  end

  def membership_request(admin, user, group)
    @user = user
    @group = group
    locale = best_locale(admin.language_preference, @user.language_preference)
    I18n.with_locale(locale) do
      mail  :to => admin.email,
            :reply_to => "#{@user.name} <#{@user.email}>",
            :subject => "#{email_subject_prefix(@group.full_name)} " + t("email.membership_request.subject", who: @user.name)
    end
  end

  def group_email(group, sender, subject, message, recipient)
    @group = group
    @sender = sender
    @message = message
    @recipient = recipient
    locale = best_locale(recipient.language_preference, sender.language_preference)
    I18n.with_locale(locale) do
      mail  :to => @recipient.email,
            :reply_to => "#{sender.name} <#{sender.email}>",
            :subject => "#{email_subject_prefix(@group.full_name)} #{subject}"
    end
  end

  def deliver_group_email(group, sender, subject, message)
    group.users.each do |user|
      unless user == sender
        GroupMailer.group_email(group, sender, subject, message, user).deliver
      end
    end
  end
end
