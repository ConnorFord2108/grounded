class Review < ApplicationRecord
  belongs_to :travel_plan
  validates :rating, numericality: { only_integer: true }
  validates :comment, presence: true
end
