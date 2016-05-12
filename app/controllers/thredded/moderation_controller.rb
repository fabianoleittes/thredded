# frozen_string_literal: true
require_dependency 'thredded/moderate_post'
module Thredded
  class ModerationController < ApplicationController
    before_action :thredded_require_login!
    before_action :load_moderatable_messageboards
    before_action :load_post, only: %i(approve_post block_post)

    def pending
      @posts =
        Thredded::Post
          .where(messageboard_id: @moderatable_messageboard)
          .pending_moderation.order_oldest_first
    end

    def history
      @post_moderation_records =
        Thredded::PostModerationRecord
          .where(messageboard_id: @moderatable_messageboard)
          .order(created_at: :desc)
          .page(params[:page] || 1)
    end

    def approve_post
      ModeratePost.run!(@post, :approved)
    end

    def block_post
      ModeratePost.run!(@post, :blocked)
    end

    private

    def load_moderatable_messageboards
      @moderatable_messageboard = thredded_current_user.thredded_can_moderate_messageboards.to_a
      if @moderatable_messageboard.empty?
        fail Pundit::NotAuthorizedError, 'You are not authorized to perform this action.'
      end
    end

    def load_post
      @post = @moderatable_messageboard.posts.find(params[:id])
    end
  end
end
