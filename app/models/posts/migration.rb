# frozen_string_literal: true

module Posts
  # Update all posts' replies, optimized for large mailing lists
  # Intended as one-time migration of existing archive, or to fix problems
  module Migration
    extend ActiveSupport::Concern

    module ClassMethods
      # acts_as_list puts the first post in the "first"/"top" position with a position of 1
      # Behavior is different if position has a default value other than null
      # Databases looks like (date, position):
      # 2012-07-01  1
      # 2012-07-05  2
      # 2012-07-05  3
      # 2012-07-08  4
      def reposition!(mailing_list)
        # Optimize for large mailing list
        transaction do
          query = mailing_list.posts.select(%i[id last_reply_at date]).order("last_reply_at, date desc")
          connection.select_all(query).each.with_index do |post, index|
            ::Post.where(id: post["id"]).update_all(position: index + 1)
          end
        end
      end

      def add_replies!(mailing_list)
        # Optimize for large mailing list

        transaction do
          ::Post.update_all "last_reply_at = date"

          # hash of arrays of hashes keyed by subject
          posts_by_subject = get_posts_by_subject(mailing_list)
          build_associations posts_by_subject
        end

        true
      end

      def get_posts_by_subject(mailing_list)
        posts_by_subject = {}

        connection.select_all(mailing_list.posts.select(%i[id date from_name subject])).each do |post|
          key = strip_subject(remove_list_prefix(post["subject"], mailing_list.subject_line_prefix)).strip.downcase
          posts = posts_by_subject[key] || []
          posts << post
          posts_by_subject[key] = posts
        end

        posts_by_subject
      end

      def build_associations(posts_by_subject)
        posts_by_subject.each do |_key, posts|
          next unless posts.size > 1
          posts = posts.sort_by { |post| post["position"].to_i }
          original = posts.first
          last_reply = posts.last
          ::Post.where(id: original["id"]).update_all(
            last_reply_at: last_reply["date"],
            last_reply_from_name: last_reply["from_name"],
            replies_count: posts.size - 1
          )
          reply_ids = posts.map { |post| post["id"] }
          reply_ids.delete original["id"]
          ::Post.where(id: reply_ids).update_all(original_id: original["id"])
        end
      end
    end
  end
end
