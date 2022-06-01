class Destination < ApplicationRecord
  has_many :travel_plans, dependent: :destroy
  has_many :reviews, through: :travel_plans, dependent: :destroy
  validates :name, :description, presence: true
  geocoded_by :name
  after_validation :geocode, if: :will_save_change_to_name?
  validates :wikidata_id, presence: true
  validates :wikidata_id, uniqueness: true
end
