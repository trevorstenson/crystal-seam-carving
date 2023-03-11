require "stumpy_png"

module CrystalCarve
  VERSION = "0.1.0"

  record EnergyData, energy : Int128, previous_x : Int32
  record PixelData, r: Int32, g: Int32, b: Int32

  alias Seam = Array({Int32, Int32})

  class Carver
    @canvas : StumpyPNG::Canvas
    @data : Array(Array(StumpyCore::RGBA))
    @energies : Array(Array(EnergyData))

    def initialize(image_path : String)
      @src = image_path
      @canvas = StumpyPNG.read(image_path)
      @data = Array(Array(StumpyCore::RGBA)).new
      @energies = Array(Array(EnergyData)).new
      reset_data
    end

    def self.from_data(data : Array(Array(PixelData)))
      
    end

    def carve_by_ratio(ratio : Float, output_path : String)
      iterations = @canvas.width - (@canvas.width * ratio).to_i
      puts "Carving #{iterations} times"
      carve_to_file(iterations, output_path)
    end

    def carve_to_file(iterations : Int32, output_path : String)
      carve(iterations)
      StumpyPNG.write(@canvas, output_path)
    end

    def carve(iterations : Int32)
      iterations.times do |i|
        create_energy_map
        seam = find_seam
        @canvas = remove_seam(seam)
        reset_data
      end
    end

    private def reset_data
      @data = Array(Array(StumpyCore::RGBA)).new
      @canvas.pixels.each_slice(@canvas.width) do |row|
        @data << row
      end
    end

    private def copy_data
      copy = Array(Array(StumpyCore::RGBA)).new
      @data.each do |row|
        copy << row.dup
      end
      copy
    end

    private def remove_seam(seam : Seam)
      new_canvas = StumpyPNG::Canvas.new(@canvas.width - 1, @canvas.height)
      copy = copy_data
      copy.each_with_index do |row, y|
        new_row = Array(StumpyCore::RGBA).new
        entry = seam[y]
        row.each_with_index do |pixel, x|
          if x != entry[0]
            new_row << pixel
          end
        end
        new_row.each_with_index do |pixel, x|
          new_canvas[x, y] = pixel
        end
      end
      new_canvas
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
      @energies = Array(Array(EnergyData)).new
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

    private def calculate_energy(pixel : StumpyCore::RGBA, neighbors : Hash(String, StumpyCore::RGBA))
      total_x = (neighbors["left"].r.to_i128 - neighbors["right"].r.to_i128).abs2
      total_x += (neighbors["left"].g.to_i128 - neighbors["right"].g.to_i128).abs2
      total_x += (neighbors["left"].b.to_i128 - neighbors["right"].b.to_i128).abs2

      total_y = (neighbors["top"].r.to_i128 - neighbors["bottom"].r.to_i128).abs2
      total_y += (neighbors["top"].g.to_i128 - neighbors["bottom"].g.to_i128).abs2
      total_y += (neighbors["top"].b.to_i128 - neighbors["bottom"].b.to_i128).abs2
      total_x + total_y
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
