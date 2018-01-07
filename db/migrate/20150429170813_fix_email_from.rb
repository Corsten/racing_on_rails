# frozen_string_literal: true

class FixEmailFrom < ActiveRecord::Migration
  def change
    Post.transaction do
      %w[ obra obrarace ].each do |list_name|
        next unless File.exist?("tmp/#{list_name}.txt")
        puts "=== #{list_name} ==="

        members = {}
        File.readlines("tmp/#{list_name}.txt").each do |member|
          if member["<"]
            name = member[/([^<]+)/].strip
            email = member.match(/<(.*)>/)[1]
          else
            name = member
            email = member
          end
          members[name] = email
        end

        next unless MailingList.where(name: list_name).any?
        MailingList.where(name: list_name).first.posts.where("from_email like '%list.obra.org'").each do |post|
          email = members[post.from_name] || Person.where_name_or_number_like(post.from_name).last.try(:email)
          if email.nil?
            puts "!! '#{post.from_name}' not found"
            email = "help@obra.org"
          else
            puts "OK #{post.from_name} to #{email}"
          end
          post.update_column :from_email, email
        end
      end
    end
  end
end
