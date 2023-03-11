require "spec"
require "../src/crystal_carve"

def raw_img_data(filename : String)
  data = Array(Array(CrystalCarve::PixelData)).new
  canvas = StumpyPNG.read(filename)
  canvas.pixels.each_slice(canvas.width) do |row|
    data << row.map { |pixel| CrystalCarve::PixelData.new(pixel.r, pixel.g, pixel.b) }
  end
  data
end

def with_timer(&block)
  start = Time.utc.to_unix_f
  yield
  puts "Time elapsed #{Time.utc.to_unix_f - start} seconds"
end