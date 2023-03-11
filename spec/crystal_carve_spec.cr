require "./spec_helper"
require "time"

describe CrystalCarve do
  it "beach to file by ratio" do
    carver = CrystalCarve::Carver.from_file("64beach.png")
    carver.carve_by_ratio(0.90, "beach_carved.png")
  end

  it "beach from raw to raw" do
    data = raw_img_data("64beach.png")
    carver = CrystalCarve::Carver.from_data(data)
    final_data = carver.carve_by_ratio(0.90)
    canvas = StumpyPNG::Canvas.new(data[0].size, data.size)
    final_data.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        canvas[x, y] = StumpyCore::RGBA.new(pixel.r, pixel.g, pixel.b, UInt16::MAX)
      end
    end
    StumpyPNG.write(canvas, "raw_beach.png")
  end

  it "does waterfall 0.98" do
    carver = CrystalCarve::Carver.from_file(
      "waterfall.png",
    )
    with_timer do
      carver.carve_by_ratio(0.98, "waterfall_carved2.png")
    end
  end
end
