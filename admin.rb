helpers do
  def title(value = nil)
    @title = value if value
    @title ? "Abba - #{@title}" : "Abba"
  end

  def dir(value)
    return if !value || value.zero?
    value > 0 ? 'positive' : 'negative'
  end

  def selected(value, present)
    ' selected ' if value == present
  end

  def required(*atts)
    atts.each do |a|
      if !params[a] || params[a].empty?
        halt 406, "#{a} required"
      end
    end
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Abba")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    return true if !settings.username?

    auth =  Rack::Auth::Basic::Request.new(request.env)
    return false unless auth.provided? && auth.basic? && auth.credentials

    auth.credentials == [settings.username, settings.password]
  end

  def ssl_enforce!
    if !request.secure? && settings.ssl
      redirect "https://#{request.host}#{request.fullpath}"
    end
  end
end

configure :production do
  before '/admin/*' do
    ssl_enforce!
  end

  before '/admin/*' do
    protected!
  end
end

# Router

get '/assets/*' do
  env['PATH_INFO'].sub!(%r{^/assets}, '')
  settings.sprockets.call(env)
end

get '/admin/experiments' do
  experiments = Abba::Experiment.query
  experiments = experiments.where(application: params[:application]) if params[:application].present?
  experiments = experiments.where(name: /#{params[:filter]}/i) if params[:filter].present?
  @experiments_by_application = experiments.sort_by { |e| [e.application, e.created_at] }.group_by(&:application)
  erb :experiments
end

get '/admin/experiments/:id/chart', :provides => 'application/json' do
  required :start_at, :end_at

  experiment = Abba::Experiment.find(params[:id])
  start_at   = Date.to_mongo(params[:start_at]).beginning_of_day
  end_at     = Date.to_mongo(params[:end_at]).end_of_day
  tranche    = params[:tranche].present? ? params[:tranche].to_sym : nil

  experiment.granular_conversion_rate(
    start_at: start_at, end_at: end_at, tranche: tranche
  ).to_json
end

put '/admin/experiments/:id/toggle' do
  @experiment = Abba::Experiment.find(params[:id])
  @experiment.running = !@experiment.running
  @experiment.save
  200
end

get '/admin/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])
  redirect('/admin/experiments') and return unless @experiment

  @start_at   = Date.to_mongo(params[:start_at]) if params[:start_at].present?
  @end_at     = Date.to_mongo(params[:end_at]) if params[:end_at].present?
  @start_at ||= [@experiment.created_at, 30.days.ago].max
  @end_at   ||= Time.now.utc

  @start_at   = @start_at.beginning_of_day
  @end_at     = @end_at.end_of_day
  @tranche    = params[:tranche].present? ? params[:tranche].to_sym : nil

  @variants   = Abba::VariantPresentor::Group.new(
    @experiment, start_at: @start_at,
    end_at: @end_at, tranche: @tranche
  )

  @params = {
    start_at: @start_at.strftime('%F'),
    end_at:   @end_at.strftime('%F'),
    tranche:  @tranche
  }

  erb :experiment
end

delete '/admin/experiments/:id' do
  @experiment = Abba::Experiment.find(params[:id])
  @experiment.destroy

  redirect '/admin/experiments'
end

get '/admin' do
  redirect '/admin/experiments'
end

get '/' do
  redirect '/admin/experiments'
end
