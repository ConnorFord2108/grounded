class TravelPlan < ApplicationRecord
  belongs_to :user
  belongs_to :destination
  validates :start_date, :end_date, presence: true
  has_many :reviews

  private

  def start_date_cannot_be_in_the_past
    if start_date.present? && start_date < Date.today
    errors.add(:start_date, "can't be in the past")
    end
  end

  def end_date_is_after_start_date
    return if end_date.blank? || start_date.blank?
      if end_date < start_date
        errors.add(:end_date, "cannot be before the start date")
      end
  end
end
