class ReviewsController < ApplicationController

  def new
  end

  def index
    @reviews = Reviews.all
  end

  def create
    @review = Review.new(review_params)
    @travel_plan = TravelPlan.find(params[:travel_plan_id])
    @review.travel_plan = @travel_plan
    if @review.save
      redirect_to destination_path(@travel_plan.destination)
    else
      render :new
    end
  end

  def destroy
    @review = Review.find(params[:id])
    @review.destroy
    redirect_to destination_path
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
