require "./spec_helper"
require "time"

describe CrystalCarve do

  it "works" do
    carver = CrystalCarve::Carver.new(
      "64beach.png",
    )
    start = Time.utc.to_unix_f
    carver.carve_to_file(20, "beach_carved.png")
    puts "Time: #{Time.utc.to_unix_f - start}"
  end

  it "does waterfall by ratio" do
    carver = CrystalCarve::Carver.new(
      "waterfall.png",
    )
    start = Time.utc.to_unix_f
    carver.carve_by_ratio(0.9, "waterfall_carved.png")
    puts "Time: #{Time.utc.to_unix_f - start}"
  end
end
