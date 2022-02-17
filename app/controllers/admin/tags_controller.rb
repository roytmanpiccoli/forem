module Admin
  class TagsController < Admin::ApplicationController
    layout "admin"

    ALLOWED_PARAMS = %i[
      id supported rules_markdown short_summary pretty_name bg_color_hex
      text_color_hex user_id alias_for badge_id requires_approval
      social_preview_template wiki_body_markdown submission_template
    ].freeze

    before_action :set_default_options, only: %i[index]
    before_action :badges_for_options, only: %i[new create edit update]
    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @q = Tag.ransack(params[:q])
      @tags = @q.result.page(params[:page]).per(50)
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = Tag.new(tag_params)
      @tag.name = params[:tag][:name].downcase

      if @tag.save
        flash[:success] = "#{@tag.name} has been created!"
        redirect_to edit_admin_tag_path(@tag)
      else
        flash[:danger] = @tag.errors_as_sentence
        render :new
      end
    end

    def edit
      @tag = Tag.find(params[:id])
      @tag_moderators = User.with_role(:tag_moderator, @tag).select(:id, :username)
    end

    def update
      @tag = Tag.find(params[:id])
      if @tag.update(tag_params)
        ::Tags::AliasRetagWorker.perform_async(@tag.id) if tag_alias_updated?
        flash[:success] = "#{@tag.name} tag successfully updated!"
      else
        flash[:error] = "The tag update failed: #{@tag.errors_as_sentence}"
      end
      redirect_to edit_admin_tag_path(@tag.id)
    end

    private

    def set_default_options
      params[:q] = { supported_not_null: "true" } if params[:q].blank?
      params[:q][:s] = "taggings_count desc" if params[:q][:s].blank?
    end

    def badges_for_options
      @badges_for_options = Badge.pluck(:title, :id)
    end

    def tag_params
      params.require(:tag).permit(ALLOWED_PARAMS)
    end

    def tag_alias_updated?
      tag_params[:alias_for].present?
    end
  end
end
