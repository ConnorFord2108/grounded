class TravelPlansController < ApplicationController

  def index
    @travel_plans = current_user.travel_plans
  end

  def new
  end

  def create
    @travel_plan_new = TravelPlan.new(plan_params)
    @travel_plan_new.user = current_user
    @destination = Destination.find(params[:destination_id])
    @recommendations = @destination.recommendations
    @review = Review.new()
    @travel_plan_new.destination = Destination.find(params[:destination_id])
    respond_to do |format|
      if @travel_plan_new.save
        format.html {redirect_to travel_plans_path, success: "Travel plan was saved into calendar successfully!"}
        format.json {render :index, status: :created, location: @travel_plans}
        # redirect_to travel_plans_path(@travel_plan_new)
      else
        # redirect_to destination_path(@travel_plan.destination)
        render "destinations/show"
      end
    end
  end


  def update
    @travel_plan = TravelPlan.find(params[:id])
    respond_to do |format|
      if @travel_plan.update(plan_params)
        format.html { redirect_to travel_plans_path, info: "Travel plan was successfully updated!"}
        format.json { render :index, status: :ok, location: @travel_plan}
      else
        redirect_to travel_plans_path, info: "Sorry, failed to update travel plan."
      end
    end
    # redirect_to travel_plans_path
  end

  def destroy
    @travel_plan = TravelPlan.find(params[:id])
    @travel_plan.destroy
    respond_to do |format|
      format.html { redirect_to travel_plans_path, danger: "Destination was successfully destroyed." }
      format.json { head :no_content }
    end
    # redirect_to travel_plans_path
  end

  private

  def plan_params
    params.require(:travel_plan).permit(:start_date, :end_date, :comment)
  end
end
