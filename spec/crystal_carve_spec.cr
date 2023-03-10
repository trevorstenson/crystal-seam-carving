require "./spec_helper"

describe CrystalCarve do

  it "works" do
    carver = CrystalCarve::Carver.new(
      "64beach.png",
    )
    carver.carve_to_file(20, "beach_carved.png")
  end

  it "does waterfall by ratio" do
    carver = CrystalCarve::Carver.new(
      "waterfall.png",
    )
    carver.carve_by_ratio(0.5, "waterfall_carved.png")
  end
end
