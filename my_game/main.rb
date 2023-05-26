require 'gosu'

# セルクラス
class Cell
  attr_accessor :color, :cleared

  def initialize(color)
    @color = color
    @cleared = false
  end

  def clear
    @cleared = true
  end

  def cleared?
    @cleared
  end
end

# パズルボードクラス
class Board
  attr_reader :grid

  def initialize(rows, cols)
    @rows = rows
    @cols = cols
    @grid = Array.new(rows) { Array.new(cols) }
    generate_cells
  end

  def generate_cells
    colors = [:red, :green, :blue, :yellow]
    @grid.each_with_index do |row, y|
      row.each_index do |x|
        color = colors.sample
        @grid[y][x] = Cell.new(color)
      end
    end
  end

  def check_matches_and_clear
    cleared_cells = []

    # 横方向のマッチをチェック
    @grid.each do |row|
      color_count = 1
      last_color = row[0].color

      row.each_with_index do |cell, index|
        if cell.color == last_color
          color_count += 1
        else
          color_count = 1
          last_color = cell.color
        end

        if color_count >= 3
          cleared_cells.concat(row[index - color_count + 1..index])
        end
      end
    end

    # 縦方向のマッチをチェック
    @grid.transpose.each do |column|
      color_count = 1
      last_color = column[0].color

      column.each_with_index do |cell, index|
        if cell.color == last_color
          color_count += 1
        else
          color_count = 1
          last_color = cell.color
        end

        if color_count >= 3
          cleared_cells.concat(column[index - color_count + 1..index])
        end
      end
    end

    cleared_cells.each(&:clear)
  end

  def fill_empty_cells
    @grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        if cell.cleared?
          colors = [:red, :green, :blue, :yellow]
          new_color = colors.sample
          @grid[y][x] = Cell.new(new_color)
        end
      end
    end
  end
end

# ゲームウィンドウクラス
class MyGame < Gosu::Window
  def initialize
    super(800, 600)
    self.caption = "Puzzle Game"

    @board = Board.new(8, 8)
    @cell_size = 50
  end

  def update
    if button_down?(Gosu::MsLeft)
      x = (mouse_x / @cell_size).to_i
      y = (mouse_y / @cell_size).to_i
      select_cell(x, y)
    end
  end

  def select_cell(x, y)
    if @selected_cell.nil?
      @selected_cell = [@board.grid[y][x], x, y]
    else
      swap_cells(x, y)
      @selected_cell = nil
    end
  end

  def swap_cells(x, y)
    selected_color = @selected_cell[0].color
    selected_x = @selected_cell[1]
    selected_y = @selected_cell[2]

    if (selected_x - x).abs + (selected_y - y).abs == 1
      @board.grid[selected_y][selected_x], @board.grid[y][x] = @board.grid[y][x], @board.grid[selected_y][selected_x]
      check_matches_and_clear
      fill_empty_cells
    end
  end

  def check_matches_and_clear
    @board.check_matches_and_clear
  end

  def fill_empty_cells
    @board.fill_empty_cells
  end

  def draw
    @board.grid.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        draw_cell(x, y, cell)
      end
    end
  end

  def draw_cell(x, y, cell)
    x_pos = x * @cell_size
    y_pos = y * @cell_size

    Gosu.draw_rect(x_pos, y_pos, @cell_size, @cell_size, Gosu::Color::WHITE)
    Gosu.draw_rect(x_pos + 2, y_pos + 2, @cell_size - 4, @cell_size - 4, Gosu::Color.const_get(cell.color.upcase))

    if cell.cleared?
      Gosu.draw_rect(x_pos + 10, y_pos + 10, @cell_size - 20, @cell_size - 20, Gosu::Color::BLACK)
    end
  end
end

# ゲームの実行
window = MyGame.new
window.show
