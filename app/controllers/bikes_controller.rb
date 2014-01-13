class OwnershipNotSavedError < StandardError
end

class BikeNotSavedError < StandardError
end

class BikeCreatorError < StandardError
end

class BikeUpdatorError < StandardError
end

class BikeTyperError < StandardError
end

class BikesController < ApplicationController
  before_filter :ensure_user_for_edit, only: [:edit, :update, :pdf]
  layout 'no_container'

  def index
    search = BikeSearcher.new(params)
    bikes = search.find_bikes.page(params[:page]).per_page(24)
    @bikes = bikes.decorate
    @attribute_select_values = search.parsed_attributes
    @query = params[:query]
    @stolen_searched = params[:stolen_included]
    @non_stolen_searched = params[:non_stolen_included]
    render :layout => 'application'
  end

  def show
    bike = Bike.unscoped.find(params[:id])
    @components = bike.components.decorate
    @bike = bike.decorate
    @stolen_notification = StolenNotification.new if @bike.stolen
    respond_to do |format|
      format.html
      format.gif  { render :qrcode => scanned_bike_url(@bike), :level => :h, :unit => 50 }
    end
  end

  def pdf
    bike = Bike.find(params[:id])
    unless bike.owner == current_user
      flash[:error] = "Sorry, that's not your bike!"
      redirect_to bike_path(bike) and return 
    end
    @bike = bike.decorate
    filename = "Registration_" + @bike.updated_at.strftime("%m%d_%H%M")[0..-1]
    unless @bike.pdf.present? && @bike.pdf.file.filename == "#{filename}.pdf"
      pdf = render_to_string pdf: filename, template: 'bikes/pdf.html.haml'
      save_path = "#{Rails.root}/tmp/#{filename}.pdf"
      File.open(save_path, 'wb') do |file| 
        file << pdf
      end
      # @bike.pdf = File.open(pdf, 'wb') { |file| file << pdf }
      @bike.pdf = File.open(save_path)
      @bike.save
    end
    # render :pdf => 'registration_pdf', :show_as_html => true
    redirect_to @bike.pdf.url
  end

  def scanned
    if params[:id]
      b = Bike.find(params[:id])
    else
      b = Bike.find_by_card_id(params[:card_id])
    end
    redirect_to bike_url(b) if b.present?
    @feedback = Feedback.new
    @card_id = params[:card_id]
  end

  def spokecard
    @qrcode = "#{bike_url(Bike.find(params[:id]))}.gif"
    render layout: false
  end

  def new
    if current_user.present?
      b_param = BParam.create(creator_id: current_user.id, params: params)
      @bike = BikeCreator.new(b_param).new_bike
      if @bike.errors.any?
        flash[:notice] = @bike.errors.full_messages
      end
    else
      @user = User.new 
    end
    render layout: 'no_header'
  end

  def create
    if params[:bike][:embeded]
      @b_param = BParam.find(params[:bike][:b_param_id])
      @bike = Bike.new
      if @b_param.created_bike.present?
        redirect_to edit_bike_url(@bike)
      end
      @b_param.update_attributes(params: params)
      @bike = BikeCreator.new(@b_param).create_bike
      if @bike.errors.any?
        @b_param.update_attributes(bike_errors: @bike.errors.full_messages)
        flash[:error] = "Whoops! There was a problem with your entry!"
        redirect_to embed_organization_url(@bike.creation_organization) and return  
      else
        redirect_to controller: :organizations, action: :embed_create_success, id: @bike.creation_organization.slug, bike_id: @bike.id and return  
      end
    else
      users_b_params = BParam.where(creator_id: current_user.id)
      begin
        @b_param = users_b_params.find(params[:bike][:b_param_id])
      rescue
        @bike = Bike.new
        flash[:error] = "Oops, that isn't your bike"
        redirect_to action: :new, layout: 'no_header' and return
      end
      if @b_param.created_bike.present?
        redirect_to edit_bike_url(@b_param.created_bike) and return
      end
      @b_param.update_attributes(params: params)
      @bike = BikeCreator.new(@b_param).create_bike
      if @bike.errors.any?
        @b_param.update_attributes(bike_errors: @bike.errors.full_messages)
        render action: :new, layout: 'no_header' and return
      end
      if @bike.payment_required
        redirect_to new_charges_url(b_param_id: @b_param.id) and return
      else
        redirect_to edit_bike_url(@bike), notice: "Bike successfully added to the index!"      
      end
    end
  end


  def edit
    bike = Bike.find(params[:id])
    begin
      BikeUpdator.new(user: current_user, b_params: params).ensure_ownership!
      rescue UserNotLoggedInError => e
        flash[:error] = e.message
        redirect_to new_user_path and return
      rescue => e
        flash[:error] = e.message
        redirect_to bike_path(bike) and return
    end
    @twined_ctypes = Ctype.where(has_twin_part: true).map(&:id).join(",")
    @bike = bike.decorate
  end


  def update
    begin
      bike = BikeUpdator.new(user: current_user, b_params: params).update_available_attributes
    rescue => e
      flash[:error] = e.message
      redirect_to bike_path(params[:id]) and return
    end
    @twined_ctypes = Ctype.where(has_twin_part: true).map(&:id).join(",")
    @bike = bike.decorate 
    if bike.errors.any?
      flash[:error] = bike.errors.full_messages
      render action: :edit
    else
      flash[:notice] = "Bike successfully updated!" 
      if @bike.stolen && params[:bike][:stolen] != false
        redirect_to edit_bike_url(@bike), layout: 'no_header' and return
      end
      redirect_to bike_url(@bike), layout: 'no_header' and return
    end
  end

protected

  def ensure_user_for_edit
    unless current_user.present?
      bike = Bike.find(params[:id])
      flash[:error] = "Whoops! You have to sign up to be able to do that"
      redirect_to bike_path(bike) and return
    end
  end

end
