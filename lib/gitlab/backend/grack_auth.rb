require_relative 'shell_env'

module Grack
  class Auth < Rack::Auth::Basic

    attr_accessor :user, :project, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      @gitlab_ci = false

      # Need this patch due to the rails mount
      # Need this if under RELATIVE_URL_ROOT
      unless Gitlab.config.gitlab.relative_url_root.empty?
        # If website is mounted using relative_url_root need to remove it first
        @env['PATH_INFO'] = @request.path.sub(Gitlab.config.gitlab.relative_url_root,'')
      else
        @env['PATH_INFO'] = @request.path
      end

      @env['SCRIPT_NAME'] = ""

      userid = env['HTTP_X_SANDSTORM_USER_ID'].encode(Encoding::UTF_8)
      Rails.logger.info "LOOKING FOR USER " + userid
      u = User.where(username: userid).first
      if u
        @user = u
        Rails.logger.info "FOUND USER #{@user.id}"

        Gitlab::ShellEnv.set_env(@user)
        @env['REMOTE_USER'] = @user.username
      end
      STDERR.puts "OK"
      if project && authorized_request?
        if ENV['GITLAB_GRACK_AUTH_ONLY'] == '1'
          # Tell gitlab-git-http-server the request is OK, and what the GL_ID is
          render_grack_auth_ok
        else
          @app.call(env)
        end
      elsif @user.nil? && !@gitlab_ci
        unauthorized
      else
        render_not_found
      end
    end

    private

    def gitlab_ci_request?(login, password)
      if login == "gitlab-ci-token" && project && project.gitlab_ci?
        token = project.gitlab_ci_service.token

        if token.present? && token == password && git_cmd == 'git-upload-pack'
          return true
        end
      end

      false
    end

    def oauth_access_token_check(login, password)
      if login == "oauth2" && git_cmd == 'git-upload-pack' && password.present?
        token = Doorkeeper::AccessToken.by_token(password)
        token && token.accessible? && User.find_by(id: token.resource_owner_id)
      end
    end

    def authenticate_user(login, password)
      user = Gitlab::Auth.new.find(login, password)

      nil # No user was found
    end

    def authorized_request?
      # Sandstorm handles authorization.
      return true

      case git_cmd
      when *Gitlab::GitAccess::DOWNLOAD_COMMANDS
        if user
          Gitlab::GitAccess.new(user, project).download_access_check.allowed?
        elsif project.public?
          # Allow clone/fetch for public projects
          true
        else
          false
        end
      when *Gitlab::GitAccess::PUSH_COMMANDS
        if user
          # Skip user authorization on upload request.
          # It will be done by the pre-receive hook in the repository.
          true
        else
          false
        end
      else
        false
      end
    end

    def git_cmd
      if @request.get?
        @request.params['service']
      elsif @request.post?
        File.basename(@request.path)
      else
        nil
      end
    end

    def project
      return @project if defined?(@project)

      @project = project_by_path(@request.path_info)
    end

    def project_by_path(path)
      if m = /^([\w\.\/-]+)\.git/.match(path).to_a
        path_with_namespace = m.last
        path_with_namespace.gsub!(/\.wiki$/, '')

        path_with_namespace[0] = '' if path_with_namespace.start_with?('/')
        Project.find_with_namespace(path_with_namespace)
      end
    end

    def render_grack_auth_ok
      [200, { "Content-Type" => "application/json" }, [JSON.dump({ 'GL_ID' => Gitlab::ShellEnv.gl_id(@user) })]]
    end

    def render_not_found
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    end
  end
end
