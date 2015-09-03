class DashboardController < Dashboard::ApplicationController
  before_action :load_projects
  before_action :event_filter, only: :show

  respond_to :html

  def show
    if current_user
      g = Group.where(name: "gitlab").first
      if !g
        g = Group.new(name: "gitlab", path:"gitlab")
        if g.save
          g.add_owner(current_user)
        else
          Rails.logger.error "failed to create gitlab group"
        end
      end

      p = Project.where(name: "repo").first
      if !p
        p = ::Projects::CreateService.new(current_user, name: "repo", path: "repo", namespace_id: g.id).execute
      end

      if p.visibility_level != 0
        p.visibility_level = 0
        p.save
      end

      redirect_to project_path(p)
      return
    end

    # Fetch only 30 projects.
    # If user needs more - point to Dashboard#projects page
    @projects_limit = 30

    @groups = current_user.authorized_groups.sort_by(&:human_name)
    @has_authorized_projects = @projects.count > 0
    @projects_count = @projects.count
    @projects = @projects.limit(@projects_limit)

    @events = Event.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events)
    @events = @events.limit(20).offset(params[:offset] || 0)
    @last_push = current_user.recent_push

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def merge_requests
    @merge_requests = get_merge_requests_collection
    @merge_requests = @merge_requests.page(params[:page]).per(PER_PAGE)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = get_issues_collection
    @issues = @issues.page(params[:page]).per(PER_PAGE)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  protected

  def load_projects
    @projects = current_user.authorized_projects.sorted_by_activity.non_archived
  end

  def load_events
    @events = Event.in_projects(current_user.authorized_projects.pluck(:id))
    @events = @event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
