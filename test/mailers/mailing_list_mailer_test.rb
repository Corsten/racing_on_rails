# coding: utf-8
# frozen_string_literal: true

require_relative "../test_helper"

# :stopdoc:
class MailingListMailerTest < ActionMailer::TestCase
  test "post" do
    post = FactoryGirl.create(:mailing_list).posts.create!(
      from_name: "Molly",
      from_email: "molly@veloshop.com",
      subject: "For Sale",
      body: "Lots of singlespeeds for sale."
    )

    post_email = MailingListMailer.post(post)
    assert_equal ["molly@veloshop.com"], post_email.from
    assert_equal "For Sale", post_email.subject
  end

  test "post private reply" do
    post = FactoryGirl.create(:mailing_list).posts.create!(
      from_name: "Molly",
      from_email: "molly@veloshop.com",
      subject: "For Sale",
      body: "Lots of singlespeeds for sale."
    )

    post_email = MailingListMailer.private_reply(post, "Scout <scout@butlerpress.com>")
    assert_equal ["molly@veloshop.com"], post_email.from
    assert_equal "For Sale", post_email.subject
    assert_equal ["scout@butlerpress.com"], post_email.to
  end

  test "receive simple" do
    assert_difference "Post.count", 1 do
      subject = "Test Email"
      from = "scott@yahoo.com"
      date = Time.zone.now
      body = "Some message for the mailing list"
      email = Mail.new
      email.content_type = "text/plain"
      email.subject = subject
      email.from = from
      email.date = date
      email.body = body
      obra_chat = FactoryGirl.create(:mailing_list)
      email.to = obra_chat.name

      MailingListMailer.receive(email.encoded)

      post = Post.first
      assert_equal(subject, post.subject, "Subject")
      assert_equal("sco..@yahoo.com", post.from_name, "from")
      assert_equal("scott@yahoo.com", post.from_email, "from_email")
      assert_equal_dates(date, post.date, "date")
      assert_equal("Some message for the mailing list", post.body, "body")
      assert_equal(obra_chat, post.mailing_list, "mailing_list")
    end
  end

  test "receive" do
    mailing_list = FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    assert_difference "Post.count", 1 do
      MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/to_archive.eml"))

      posts = Post.order(:date)
      post_from_db = posts.last
      assert_equal "Some free stuff . . . . Shimano road pedals", post_from_db.subject, "Subject"
      assert_equal "EAL", post_from_db.from_name, "from"
      assert_equal "anquetil@yahoo.com", post_from_db.from_email, "from_email"
      assert_equal_dates "Tue Apr 28 16:02:20 PST 2015", post_from_db.date, "Post date", "%a %b %d %H:%M:%S PST %Y"
      assert_equal mailing_list, post_from_db.mailing_list, "mailing_list"
      assert post_from_db.body["Free standing adjustable basketball hoop"], "body"
    end
  end

  test "receive should save reply" do
    FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    Post.expects(:save).returns(true)
    Post.any_instance.expects(:save!).never
    MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/to_archive.eml"))
  end

  test "receive no list matches" do
    assert_difference "Post.count", 0 do
      MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/to_archive.eml"))
    end
  end

  test "receive invalid byte sequence" do
    FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/invalid_byte_sequence.eml"))
  end

  test "receive rich text" do
    mailing_list = FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    assert_difference "Post.count", 1 do
      MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/rich.eml"))

      post_from_db = Post.order(:date).last
      assert_equal("Rich Text", post_from_db.subject, "Subject")
      assert_equal("Scott Willson", post_from_db.from_name, "from")
      assert_equal("scott.willson@gmail.com", post_from_db.from_email, "from_email")
      assert_equal("Sat Jan 28 07:02:18 PST 2006", post_from_db.date.strftime("%a %b %d %I:%M:%S PST %Y"), "date")
      assert_equal(mailing_list, post_from_db.mailing_list, "mailing_list")
      assert post_from_db.body["Rich text message with some formatting and a small attachment"], "body"
    end
  end

  test "receive bad part encoding" do
    FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    assert_difference "Post.count", 1 do
      MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/bad_encoding.eml"))

      post_from_db = Post.order(:date).last
      assert_equal("cyclist missing-- Mark Bosworth", post_from_db.subject, "Subject")
      assert(post_from_db.body["Thanks in advance for your help Kenji"], "body")
    end
  end

  test "receive outlook" do
    mailing_list = FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    assert_difference "Post.count", 1 do
      MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/outlook.eml"))

      post_from_db = Post.order(:date).last
      assert_equal("Stinky Outlook Email", post_from_db.subject, "Subject")
      assert_equal("Scott Willson", post_from_db.from_name, "from")
      assert_equal("scott.willson@gmail.com", post_from_db.from_email, "from_email")
      assert_equal("Sat Jan 28 07:28:31 PST 2006", post_from_db.date.strftime("%a %b %d %I:%M:%S PST %Y"), "date")
      assert_equal(mailing_list, post_from_db.mailing_list, "mailing_list")
      expected_body = File.read("#{Rails.root}/test/fixtures/email/outlook_expected.eml")
      assert_equal(expected_body, post_from_db.body, "body")
    end
  end

  test "receive html" do
    mailing_list = FactoryGirl.create(:mailing_list, name: "obra", friendly_name: "OBRA Chat", subject_line_prefix: "OBRA Chat")
    assert_difference "Post.count", 1 do
          MailingListMailer.receive(File.read("#{Rails.root}/test/fixtures/email/html.eml"))

          post_from_db = Post.order(:date).last
          assert_equal("Thunderbird HTML", post_from_db.subject, "Subject")
          assert_equal("Scott Willson", post_from_db.from_name, "from")
          assert_equal("scott.willson@gmail.com", post_from_db.from_email, "from_email")
          assert_equal("Sat Jan 28 10:19:04 PST 2006", post_from_db.date.strftime("%a %b %d %I:%M:%S PST %Y"), "date")
          assert_equal(mailing_list, post_from_db.mailing_list, "mailing_list")
          expected_body = %Q{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta content="text/html;charset=ISO-8859-1" http-equiv="Content-Type">
</head>
<body bgcolor="#ffffff" text="#000000">
<h3>Race Results</h3>
<table border="1" cellpadding="2" cellspacing="2" width="100%">
  <tbody>
    <tr>
      <td valign="top"><b>Place<br>
      </b></td>
      <td valign="top"><b>Person<br>
      </b></td>
    </tr>
    <tr>
      <td valign="top">1<br>
      </td>
      <td valign="top">Ian Leitheiser<br>
      </td>
    </tr>
    <tr>
      <td valign="top">2<br>
      </td>
      <td valign="top">Kevin Condron<br>
      </td>
    </tr>
  </tbody>
</table>
<br>
</body>
</html>}
          assert_equal(expected_body, post_from_db.body, "body")
    end
  end
end
