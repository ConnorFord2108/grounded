class TravelPlan < ApplicationRecord
  belongs_to :user
  belongs_to :destination
  validates :start_date, :end_date, presence: true
  has_many :reviews
end
