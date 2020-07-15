module PlantsHelper
  def completion_percentage(plant)
    total = plant.attributes.keys.without('id', 'inserted_at', 'updated_at').count
    complete = plant.attributes.values.reject(&:nil?).count
    ((complete.to_f / total.to_f).to_f * 100).to_i # rubocop:todo Style/FloatDivision
  end
end
