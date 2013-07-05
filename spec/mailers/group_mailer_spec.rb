require "spec_helper"

describe GroupMailer do

  describe '#new_membership request' do
    it 'sends email to all the admins' do
      @group = create(:group)
      @user = create(:user)
      @membership = @group.add_request!(@user)
      mailer = double "mailer"

      mailer.should_receive(:deliver)
      GroupMailer.should_receive(:membership_request).with(@group.admins.first, @user, @group).
        and_return(mailer)
      GroupMailer.new_membership_request(@membership)
    end
  end

  describe '#membership_request' do
    before do
      @group = create(:group)
      @admin = create(:user, language_preference: "en")
      @user = create(:user, language_preference: "en")
      @mail = GroupMailer.membership_request(@admin, @user, @group)
    end

    it 'renders the subject' do
      @mail.subject.should ==
        "[Loomio: #{@group.full_name}] New membership request from #{@user.name}"
    end

    it "sends email to group admins" do
      @mail.to.should == [@admin.email]
    end

    it 'renders the sender email' do
      @mail.from.should == ['noreply@loomio.org']
    end

    it 'assigns correct reply_to' do
      @mail.reply_to.should == [@user.email]
    end

    it 'assigns confirmation_url for email body' do
      @mail.body.encoded.should match(/\/groups\/#{@group.id}/)
    end
  end

  describe "#deliver_group_email" do
    let(:group) { stub_model Group }

    it "sends email to every group member except the sender" do
      sender = stub_model User
      member = stub_model User
      group.stub(:users).and_return([sender, member])
      email_subject = "i have something really important to say!"
      email_body = "goobly"
      mailer = double "mailer"

      mailer.should_receive(:deliver)
      GroupMailer.should_receive(:group_email).
        with(group, sender, email_subject, email_body, member).
        and_return(mailer)
      GroupMailer.should_not_receive(:group_email).
        with(group, sender, email_subject, email_body, sender)
      GroupMailer.deliver_group_email(group, sender,
                                      email_subject, email_body)
    end
  end

  describe "#group_email" do
    before :all do
      @group = stub_model Group, :name => "Blue", :admin_email => "goodbye@world.com"
      @sender = stub_model User, :name => "Marvin"
      @recipient = stub_model User, :email => "hello@world.com"
      @subject = "meeby"
      @message = "what in the?!"
      @mail = GroupMailer.group_email(@group, @sender, @subject,
                                      @message, @recipient)
    end

    subject { @mail }

    its(:subject) { should == "[Loomio: #{@group.full_name}] #{@subject}" }
    its(:to) { should == [@recipient.email] }
    its(:from) { should == ['noreply@loomio.org'] }
  end
end
