require_dependency 'issues_controller'

module IssuesControllerPatch
  def self.included(base) # :nodoc:
    base.module_eval do
      alias_method_chain :new,:post_youroom
      alias_method_chain :show,:post_youroom
      alias_method_chain :create,:post_youroom
      alias_method_chain :update,:post_youroom
    end
  end

  def new_with_post_youroom
    @project_room = ProjectRoom.find_by_project_id(@project.id)
    new_without_post_youroom
  end

  def show_with_post_youroom
    @project_room = ProjectRoom.find_by_project_id(@project.id)
    show_without_post_youroom
  end

  def create_with_post_youroom
   unless params[:youroom].blank?
     return if check_register_room @project.id
     return if check_oauth_authentication
   end

    create_without_post_youroom

  end

  def update_with_post_youroom
    params[:request] = request

    unless params[:youroom].blank?
      return if check_register_room @project.id
      return if check_oauth_authentication
    end

    update_without_post_youroom
  end

  private
  def check_register_room project_id
    @project_room = ProjectRoom.find_by_project_id(project_id)
    if @project_room.nil? || @project_room.room_num.blank?
      flash.now[:error] = "Please set of youRoom before use"
      render :action => 'new'
      return true
    end
    return false
  end

  def check_oauth_authentication
    oauth_token = OauthToken.find_by_user_id(User.current.id)
    if oauth_token.blank? || oauth_token.access_token.blank?
      redirect_to params.merge :controller => 'youroom',:action => 'get_access_token',:project_id => @project.id
      return true
    end
    return false
  end
end


IssuesController.send(:include,IssuesControllerPatch)
