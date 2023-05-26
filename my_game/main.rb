require 'gosu'

# ゲームウィンドウのクラス
class GameWindow < Gosu::Window
  def initialize(width, height)
    super(width, height)
    self.caption = 'パズルゲーム'

    @board = Board.new(8, 8) # ボードの作成（8x8のセル）
    @cell_size = 64 # セルのサイズ
    @selected_cell = nil # 選択中のセル
  end

  def update
    # ゲームの状態やアニメーションの更新処理
  end

  def draw
    # ウィンドウの描画処理
    @board.cells.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        draw_cell(cell, x, y)
      end
    end
  end

  def draw_cell(cell, x, y)
    # セルの描画処理
    color = cell.color # セルの色
    x_pos = x * @cell_size # セルのX座標
    y_pos = y * @cell_size # セルのY座標

    Gosu.draw_rect(x_pos, y_pos, @cell_size, @cell_size, color)
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      handle_mouse_click
    end
  end

  def handle_mouse_click
    x = mouse_x / @cell_size # クリックされた位置のX座標をセルのインデックスに変換
    y = mouse_y / @cell_size # クリックされた位置のY座標をセルのインデックスに変換

    if @selected_cell.nil?
      @selected_cell = [@board.get_cell(x, y), x, y]
    else
      cell, prev_x, prev_y = @selected_cell
      if cell != @board.get_cell(x, y) && @board.can_swap?(prev_x, prev_y, x, y)
        @board.swap_cells(prev_x, prev_y, x, y)
        check_matches_and_clear
      end
      @selected_cell = nil
    end
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      handle_mouse_down
    end
  end
  
  def button_up(id)
    case id
    when Gosu::MsLeft
      handle_mouse_up
    end
  end
  
  def handle_mouse_down
    x = mouse_x / @cell_size
    y = mouse_y / @cell_size
  
    @selected_cell = @board.get_cell(x, y)
    @selected_cell_origin = [x, y]
  end
  
  def handle_mouse_up
    return if @selected_cell.nil?
  
    x = mouse_x / @cell_size
    y = mouse_y / @cell_size
  
    if @board.can_swap?(*@selected_cell_origin, x, y)
      @board.swap_cells(*@selected_cell_origin, x, y)
      @selected_cell.x, @selected_cell.y = x, y
      @board.get_cell(x, y).x, @board.get_cell(x, y).y = *@selected_cell_origin
      check_matches_and_clear
    end
  
    @selected_cell = nil
    @selected_cell_origin = nil
  end
  
  
  def update
    if @selected_cell
      x = mouse_x / @cell_size
      y = mouse_y / @cell_size
  
      @selected_cell.x = x
      @selected_cell.y = y
    end
  
    # ゲームの状態やアニメーションの更新処理
  end
  
  def draw
    # ウィンドウの描画処理
    @board.cells.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        draw_cell(cell, x, y)
      end
    end
  
    if @selected_cell
      draw_selected_cell
    end
  end
  
  def draw_selected_cell
    x = mouse_x / @cell_size
    y = mouse_y / @cell_size
  
    x_pos = x * @cell_size
    y_pos = y * @cell_size
  
    # 選択中のセルを描画する
    Gosu.draw_rect(x_pos, y_pos, @cell_size, @cell_size, Gosu::Color::GRAY, 2)
  end

  def check_matches_and_clear
    matches = @board.find_matches
    if matches.any?
      matches.each do |match|
        match.each do |cell|
          cell.clear
        end
      end
      @board.fill_empty_cells
    end
  end
end

# セルのクラス
class Cell
  attr_accessor :color, :cleared, :x, :y

  def initialize(color)
    @color = color
    @cleared = false
    @x = 0
    @y = 0
  end

  def clear
    @cleared = true
  end

  def cleared?
    @cleared
  end
end

# ボードのクラス
class Board
  attr_reader :cells

  def initialize(width, height)
    @width = width
    @height = height
    @colors = [Gosu::Color::RED, Gosu::Color::GREEN, Gosu::Color::BLUE] # セルの色のリスト

    create_cells
  end

  def create_cells
    @cells = Array.new(@height) do
      Array.new(@width) { Cell.new(random_color) }
    end
  end

  def random_color
    @colors.sample
  end

  def get_cell(x, y)
    @cells[y][x]
  end

  def can_swap?(x1, y1, x2, y2)
    return false unless valid_coordinates?(x1, y1) && valid_coordinates?(x2, y2)

    (x1 - x2).abs + (y1 - y2).abs == 1 # 隣り合ったセルのみ交換可能
  end

  def valid_coordinates?(x, y)
    x >= 0 && x < @width && y >= 0 && y < @height
  end

  def swap_cells(x1, y1, x2, y2)
    @cells[y1][x1], @cells[y2][x2] = @cells[y2][x2], @cells[y1][x1]
  end

  def find_matches
    matches = []

    # 横方向のマッチを探す
    @cells.each do |row|
      current_color = nil
      match_length = 0
      match = []

      row.each do |cell|
        if cell.color == current_color
          match_length += 1
          match << cell
        else
          if match_length >= 3
            matches << match
          end
          current_color = cell.color
          match_length = 1
          match = [cell]
        end
      end

      if match_length >= 3
        matches << match
      end
    end

    # 縦方向のマッチを探す
    @cells.transpose.each do |column|
      current_color = nil
      match_length = 0
      match = []

      column.each do |cell|
        if cell.color == current_color
          match_length += 1
          match << cell
        else
          if match_length >= 3
            matches << match
          end
          current_color = cell.color
          match_length = 1
          match = [cell]
        end
      end

      if match_length >= 3
        matches << match
      end
    end

    matches
  end

  def fill_empty_cells
    @cells.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        if cell.cleared?
          cell.color = random_color
          cell.clear = false
        end
      end
    end
  end
end

# ゲームウィンドウを開始する
window = GameWindow.new(640, 640)
window.show
