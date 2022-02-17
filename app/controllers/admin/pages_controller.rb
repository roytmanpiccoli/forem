module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    PAGE_ALLOWED_PARAMS = %i[
      title slug body_markdown body_html body_json description template
      is_top_level_path social_image landing_page
    ].freeze

    def index
      @pages = Page.all.order(created_at: :desc)
      @code_of_conduct = Page.find_by(slug: Page::CODE_OF_CONDUCT_SLUG)
      @privacy = Page.find_by(slug: Page::PRIVACY_SLUG)
      @terms = Page.find_by(slug: Page::TERMS_SLUG)
    end

    def new
      @landing_page = Page.landing_page

      if (slug = params[:slug])
        prepopulate_new_form(slug)
      else
        @page = Page.new
      end
    end

    def edit
      @page = Page.find(params[:id])
      @landing_page = Page.landing_page
    end

    def update
      @page = Page.find(params[:id])

      if @page.update(page_params)
        flash[:success] = "Page has been successfully updated."
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :edit
      end
    end

    def create
      @page = Page.new(page_params)

      if @page.save
        flash[:success] = "Page has been successfully created."
        redirect_to admin_pages_path
      else
        flash.now[:error] = @page.errors_as_sentence
        render :new
      end
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy

      flash[:success] = "Page has been successfully deleted."
      redirect_to admin_pages_path
    end

    private

    def page_params
      params.require(:page).permit(PAGE_ALLOWED_PARAMS)
    end

    def prepopulate_new_form(slug)
      html = view_context.render partial: "pages/coc_text",
                                 locals: {
                                   community_name: view_context.community_name,
                                   contact_link: view_context.contact_link
                                 }
      @page = case slug
              when Page::CODE_OF_CONDUCT_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Code of Conduct",
                  description: "A page that describes how to behave on this platform",
                  is_top_level_path: true,
                )
              when Page::PRIVACY_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Privacy Policy",
                  description: "A page that describes the privacy policy",
                  is_top_level_path: true,
                )
              when Page::TERMS_SLUG
                Page.new(
                  slug: slug,
                  body_html: html,
                  title: "Terms of Use",
                  description: "A page that describes the terms of use for the application",
                  is_top_level_path: true,
                )
              else
                Page.new
              end
    end
  end
end
