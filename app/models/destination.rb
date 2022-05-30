class Destination < ApplicationRecord
  has_many :reviews, through: :travel_plans, dependent: :destroy
  validates :name, :description, presence: true
end
