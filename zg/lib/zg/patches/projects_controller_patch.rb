module Zg
  module Patches
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          before_action :validate_github_authorized, except: :index, if: -> { User.current.logged? }
          after_action :build_git_repo_url, only: %i[create update]
        end
      end

      module InstanceMethods
        def validate_github_authorized
          return unless find_project.sync_with_github?
          return if User.current.authorized_github? || !User.current.logged?
          flash[:error] = 'Please authorize your account with Github'
          redirect_to my_account_path(User.current)
        end

        def build_git_repo_url
          return if @project.errors.any?
          git_repo_url = params[:project][:git_repo_url]
          git_repo_name = git_repo_url.sub('https://github.com/', '')
          # @TODO: Check if ventura project exist?
          @project.build_ventura_project(git_repo_url: git_repo_url, git_repo_name: git_repo_name).save
        end
      end
    end
  end
end

unless ProjectsController.included_modules.include?(Zg::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, Zg::Patches::ProjectsControllerPatch)
end
