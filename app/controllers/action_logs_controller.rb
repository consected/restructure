class ActionLogsController < ApplicationController
#  before_action :authenticate_admin!
  include AdminControllerHandler
  
  def index
    @action_logs = Dir.glob("action_logs/*_action_log-*.log").sort
  end
  
  def show
    id = params[:id]
    logger.info "ID: #{id}"
    f = File.basename(id, '.log')
    logger.info "File: #{f}"
    fn = "action_logs/#{f}.log"
    @action_log = []
    File.open(fn).each { |l|
      if l[0].to_s != '#'
        ls = l.split(' -- : ',2)
        j = JSON.parse ls.last

        @action_log << {title: ls.first, detail: j }
      end
      
    }
    render json: @action_log
  end
  
  private
    def set_instance_from_id
      
    end
end

