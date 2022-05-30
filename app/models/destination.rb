class Destination < ApplicationRecord
  has_many :reviews, through: :travel_plans, dependent: :destroy
  validates :name, :description, presence: true
  validates :wikidata_id, presence: true
  validates :wikidata_id, uniqueness: true
end
