require "stumpy_png"

module CrystalCarve
  VERSION = "0.1.0"

  record EnergyData, energy : Int128, previous_x : Int32
  record PixelData, r : UInt16, g : UInt16, b : UInt16

  alias Seam = Array({Int32, Int32})

  class Carver
    @data : Array(Array(PixelData)) = Array(Array(PixelData)).new
    @energies : Array(Array(EnergyData)) = Array(Array(EnergyData)).new

    def initialize(data : Array(Array(PixelData)))
      @data = data
    end

    def self.from_file(input_path : String)
      data = Array(Array(PixelData)).new
      canvas = StumpyPNG.read(input_path)
      canvas.pixels.each_slice(canvas.width) do |row|
        data << row.map { |pixel| PixelData.new(pixel.r, pixel.g, pixel.b) }
      end
      Carver.new(data)
    end

    def self.from_data(data : Array(Array(PixelData)))
      Carver.new(data)
    end

    def carve_by_ratio(ratio : Float, output_path : String)
      iterations = @data[0].size - (@data[0].size * ratio).to_i
      final_data = carve(iterations)
      StumpyPNG.write(to_canvas(final_data), output_path)
    end

    def carve_by_ratio(ratio : Float)
      iterations = @data[0].size - (@data[0].size * ratio).to_i
      carve(iterations)
    end

    def carve_to_file(iterations : Int32, output_path : String)
      final_data = carve(iterations)
      StumpyPNG.write(to_canvas(final_data), output_path)
    end

    private def carve(iterations : Int32)
      run_data = @data
      iterations.times do |i|
        create_energy_map
        seam = find_seam
        run_data = remove_seam(run_data, seam)
      end
      run_data
    end

    private def to_canvas(data : Array(Array(PixelData)))
      canvas = StumpyPNG::Canvas.new(data[0].size, data.size)
      data.each_with_index do |row, y|
        row.each_with_index do |pixel, x|
          canvas[x, y] = StumpyCore::RGBA.new(pixel.r, pixel.g, pixel.b, UInt16::MAX)
        end
      end
      canvas
    end

    private def remove_seam(data : Array(Array(PixelData)), seam : Seam)
      new_data = Array(Array(PixelData)).new
      data.each_with_index do |row, y|
        new_row = Array(PixelData).new
        entry = seam[y]
        row.each_with_index do |pixel, x|
          if x != entry[0]
            new_row << pixel
          end
        end
        new_data << new_row
      end
      new_data
    end

    def find_seam
      prev_energies = @energies[0]
      (1..@energies.size - 1).each do |y|
        pixel_energies_row = @energies[y]
        seam_energies_row = Array(EnergyData).new
        pixel_energies_row.each_with_index do |p_energy, index|
          left = Math.max(0, index - 1)
          right = Math.min(pixel_energies_row.size - 1, index + 1)
          range = left...right # inclusive
          smallest_idx = 0
          smallest = prev_energies[range][0]
          prev_energies[range].each_with_index do |e, i|
            if smallest.nil? || e.energy < smallest.energy
              smallest = e
              smallest_idx = i
            end
          end
          new_energy = p_energy.energy + smallest.energy
          seam_energies_row << EnergyData.new(new_energy, smallest_idx + left)
        end
        prev_energies = seam_energies_row
        @energies[y] = seam_energies_row
      end
      min_bottom_row_idx = prev_energies.each_with_index.min_by { |e, i| e.energy }[1]
      seam = Seam.new
      seam_point_x = min_bottom_row_idx
      (@energies.size - 1).downto(0) do |y|
        seam << {seam_point_x, y}
        seam_point_x = @energies[y][seam_point_x].previous_x
      end
      seam.reverse!
    end

    private def create_energy_map
      @energies.clear
      (0..@data.size - 1).each do |row|
        energy_row = Array(EnergyData).new
        (0..@data[row].size - 1).each do |col|
          neighbors = get_neighbors(row, col)
          energy = calculate_energy(@data[row][col], neighbors)
          energy_row << EnergyData.new(energy, 0)
        end
        @energies << energy_row
      end
    end

    private def calculate_energy(pixel : PixelData, neighbors : Hash(String, PixelData))
      total_x = neighbors["left"].r.to_i128 - neighbors["right"].r
      total_x += neighbors["left"].g.to_i128 - neighbors["right"].g
      total_x += neighbors["left"].b.to_i128 - neighbors["right"].b

      total_y = neighbors["top"].r.to_i128 - neighbors["bottom"].r
      total_y += neighbors["top"].g.to_i128 - neighbors["bottom"].g
      total_y += neighbors["top"].b.to_i128 - neighbors["bottom"].b
      (total_x + total_y).abs2
    end

    private def get_neighbors(x : Int32, y : Int32)
      left = x == 0 ? @data[@data.size - 1][y] : @data[x][y]
      right = x == @data.size - 1 ? @data[0][y] : @data[x + 1][y]
      top = y == 0 ? @data[x][@data[x].size - 1] : @data[x][y - 1]
      bottom = y == @data[x].size - 1 ? @data[x][0] : @data[x][y + 1]
      {"left" => left, "right" => right, "top" => top, "bottom" => bottom}
    end
  end
end
