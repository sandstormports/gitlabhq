require_relative 'shell_env'

module Grack
  class AuthSpawner
    def self.call(env)
      # Avoid issues with instance variables in Grack::Auth persisting across
      # requests by creating a new instance for each request.
      Auth.new({}).call(env)
    end
  end

  class Auth < Rack::Auth::Basic

    attr_accessor :user, :project, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      @ci = false

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

      u = User.where(email: userid + "@example.com").first
      if u
        @user = u
        Rails.logger.info "FOUND USER #{@user.id}"

        permission_list = env["HTTP_X_SANDSTORM_PERMISSIONS"].split(',')
        project = Project.where(name: "repo").first
        role = Gitlab::Access::GUEST
        if permission_list.include? 'owner'
          role = Gitlab::Access::OWNER
        elsif permission_list.include? 'master'
          role = Gitlab::Access::MASTER
        elsif permission_list.include? 'developer'
          role = Gitlab::Access::DEVELOPER
        elsif permission_list.include? 'reporter'
          role = Gitlab::Access::REPORTER
        end
        if project
          project.team.add_user(u, role)
        end

        Gitlab::ShellEnv.set_env(@user)
        @env['REMOTE_USER'] = @user.username
      end
      STDERR.puts "OK"

      if project && authorized_request?
        # Tell gitlab-workhorse the request is OK, and what the GL_ID is
        render_grack_auth_ok
      elsif @user.nil? && !@ci
        unauthorized
      else
        render_not_found
      end
    end

    private

    def auth!
      return unless @auth.provided?

      return bad_request unless @auth.basic?

      # Authentication with username and password
      login, password = @auth.credentials

      # Allow authentication for GitLab CI service
      # if valid token passed
      if ci_request?(login, password)
        @ci = true
        return
      end

      @user = authenticate_user(login, password)

      if @user
        Gitlab::ShellEnv.set_env(@user)
        @env['REMOTE_USER'] = @auth.username
      end
    end

    def ci_request?(login, password)
      matched_login = /(?<s>^[a-zA-Z]*-ci)-token$/.match(login)

      if project && matched_login.present? && git_cmd == 'git-upload-pack'
        underscored_service = matched_login['s'].underscore

        if underscored_service == 'gitlab_ci'
          return project && project.valid_build_token?(password)
        elsif Service.available_services_names.include?(underscored_service)
          service_method = "#{underscored_service}_service"
          service = project.send(service_method)

          return service && service.activated? && service.valid_token?(password)
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
      return true if @ci

      case git_cmd
      when *Gitlab::GitAccess::DOWNLOAD_COMMANDS
        if !Gitlab.config.gitlab_shell.upload_pack
          false
        elsif user
          Gitlab::GitAccess.new(user, project).download_access_check.allowed?
        elsif project.public?
          # Allow clone/fetch for public projects
          true
        else
          false
        end
      when *Gitlab::GitAccess::PUSH_COMMANDS
        if !Gitlab.config.gitlab_shell.receive_pack
          false
        elsif user
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
      repo_path =
        if @request.path_info =~ /^([\w\.\/-]+)\.wiki\.git/
          ProjectWiki.new(project).repository.path_to_repo
        else
          project.repository.path_to_repo
        end

      [
        200,
        { "Content-Type" => "application/json" },
        [JSON.dump({
          'GL_ID' => Gitlab::ShellEnv.gl_id(@user),
          'RepoPath' => repo_path,
        })]
      ]
    end

    def render_not_found
      [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
    end
  end
end
