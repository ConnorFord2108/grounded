class TravelPlansController < ApplicationController

  def index
    @travel_plans = current_user.travel_plans
  end

  def new
  end

  def create
    @travel_plan = TravelPlan.new(plan_params)
    @travel_plan.user = current_user
    @travel_plan.destination = Destination.find(params[:destination_id])
    if @travel_plan.save
      redirect_to destination_path
    else
      render :new
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
