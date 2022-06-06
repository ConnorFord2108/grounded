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
    if @travel_plan_new.save
      redirect_to travel_plans_path(@travel_plan_new)
    else
      # redirect_to destination_path(@travel_plan.destination)
      render "destinations/show"
    end
  end

  def destroy
    @travel_plan = TravelPlan.find(params[:id])
    @travel_plan.destroy
    redirect_to
  end

  private

  def plan_params
    params.require(:travel_plan).permit(:start_date, :end_date, :comment)
  end
end
