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
        redirect_to travel_plans_path, alert: "Travel plan was saved into calendar successfully!"
        # redirect_to travel_plans_path(@travel_plan_new)
      else
        render "destinations/show"
      end
  end


  def update
    @travel_plan = TravelPlan.find(params[:id])
      if @travel_plan.update(plan_params)
        redirect_to travel_plans_path, alert: "Travel plan was successfully updated!"
      else
        redirect_to travel_plans_path, alert: "Sorry, failed to update travel plan."
      end
    # redirect_to travel_plans_path
  end

  def destroy
    @travel_plan = TravelPlan.find(params[:id])
    @travel_plan.destroy
    redirect_to travel_plans_path, alert: "Destination was successfully destroyed."
    # redirect_to travel_plans_path
  end

  private

  def plan_params
    params.require(:travel_plan).permit(:start_date, :end_date, :comment)
  end
end
