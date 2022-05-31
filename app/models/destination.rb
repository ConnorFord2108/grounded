class Destination < ApplicationRecord
  has_many :reviews, through: :travel_plans, dependent: :destroy
  validates :address, :description, presence: true
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?
end
