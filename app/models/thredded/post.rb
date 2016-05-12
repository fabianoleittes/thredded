# frozen_string_literal: true
module Thredded
  class Post < ActiveRecord::Base
    include PostCommon
    include ContentModerationState

    belongs_to :user,
               class_name: Thredded.user_class,
               inverse_of: :thredded_posts
    belongs_to :messageboard,
               counter_cache: true
    belongs_to :postable,
               class_name:    'Thredded::Topic',
               inverse_of:    :posts,
               counter_cache: true
    belongs_to :user_detail,
               inverse_of:    :posts,
               primary_key:   :user_id,
               foreign_key:   :user_id,
               counter_cache: true
    has_many :moderation_records,
             class_name: 'Thredded::PostModerationRecord',
             dependent: :nullify

    validates :messageboard_id, presence: true

    # @param [Integer] per_page
    # @param [Thredded.user_class] user
    def page(per_page: self.class.default_per_page, user:)
      1 + postable.posts.visible_to_user(user).where(postable.posts.arel_table[:id].lt(id)).count / per_page
    end

    def private_topic_post?
      false
    end

    def user_detail
      super || build_user_detail
    end

    # @return [ActiveRecord::Relation<Thredded.user_class>] users from the list of user names that can read this post.
    def readers_from_user_names(user_names)
      DbTextSearch::CaseInsensitive
        .new(Thredded.user_class.thredded_messageboards_readers([messageboard]), Thredded.user_name_column)
        .in(user_names)
    end
  end
end
