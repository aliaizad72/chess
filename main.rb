# frozen_string_literal: true

require 'colorize'
# class that stores the pieces in the game
class Board
  attr_accessor :array
  attr_reader :size

  def initialize(size)
    @size = size
    @array = Array.new(size).map { Array.new(size) }
  end

  def insert(board_piece:, row:, column:)
    array[row][column] = board_piece
  end

  def move(from_row:, from_column:, to_row:, to_column:)
    element = select(row: from_row, column: from_column)
    remove(row: from_row, column: from_column)
    insert(board_piece: element, row: to_row, column: to_column)
  end

  def select(row:, column:)
    array[row][column]
  end

  def remove(row:, column:)
    array[row][column] = nil
  end
end

# superclass chess pieces
class Piece
  attr_accessor :row, :column
  attr_reader :color

  def initialize(color:, row:, column:)
    @color = color
    @row = row
    @column = column
  end

  def all_moves
    # array with each possible vector
    all_vectors = {}
    move_directions.each do |direction|
      vector = base_vectors(direction)
      vectors = max_range_vectors(vector, scalar)
      all_vectors[direction] = vectors
    end
    all_vectors
  end

  def initials
    # implement in subclass
  end

  def to_s
    initials.colorize(color.to_sym)
  end

  def moves_sums
    hash = all_moves
    hash.each_value do |moves|
      moves.each do |move|
        move[0] = move[0] + row
        move[1] = move[1] + column
      end
    end
    hash
  end

  def filter_moves(board)
    move_hash = moves_sums
    move_hash = filter_in_bounds(board: board, move_hash: move_hash)
    filter_blocked_path(board: board, move_hash: move_hash)
  end

  # private

  def filter_in_bounds(board:, move_hash:)
    move_hash.each_value do |moves|
      moves.select! { |move| move.all? { |i| i >= 0 && i < board.size } }
    end
    move_hash
  end

  def filter_blocked_path(board:, move_hash:)
    move_hash.each do |direction, moves|
      next if moves.empty?

      index = find_end_index(board: board, move_array: moves)
      filtered = moves[0, index + 1]
      move_hash[direction] = filtered
    end
    move_hash
  end

  def find_end_index(board:, move_array:)
    move_array.each do |move|
      return move_array.index(move) if board.empty?(row: move[0], column: move[1]) && move_array.last == move

      if board.enemy?(obj: self, row: move[0], column: move[1])
        return move_array.index(move)
      elsif board.ally?(piece: self, row: move[0], column: move[1])
        return move_array.index(move) - 1
      end
    end
  end

  def move_directions
    %i[north
       north_east
       east
       south_east
       south
       south_west
       west
       north_west]
  end

  def scalar
    1
  end

  def base_vectors(direction)
    { north: [1, 0],
      north_east: [1, 1],
      east: [0, 1],
      south_east: [-1, 1],
      south: [-1, 0],
      south_west: [-1, -1],
      west: [0, -1],
      north_west: [1, -1] }[direction]
  end

  def max_range_vectors(vector, scalar)
    product = []
    (1..scalar).to_a.each do |multiplier|
      vector_product = vector_multiply(vector, multiplier)
      product.push(vector_product)
    end
    product
  end

  def vector_multiply(vector, multiplier)
    vector_product = []
    vector_product[0] = vector[0] * multiplier
    vector_product[1] = vector[1] * multiplier
    vector_product
  end
end

# superclass for pieces that can move 7 steps
class SevenStepPiece < Piece
  def scalar
    7
  end
end

# chess piece Queen
class Queen < SevenStepPiece
  def initials
    'Q'
  end
end

# chess piece Rook
class Rook < SevenStepPiece
  def initials
    'R'
  end

  def move_directions
    %i[north
       south
       west
       east]
  end
end

# chess piece Bishop
class Bishop < SevenStepPiece
  def initials
    'B'
  end

  def move_directions
    %i[north_east
       north_west
       south_east
       south_west]
  end
end

# chess piece Knight
class Knight < Piece
  def initials
    'N'
  end

  def all_moves
    { l1: [[1, 2]],
      l2: [[1, -2]],
      l3: [[2, 1]],
      l4: [[2, -1]],
      l5: [[-1, 2]],
      l6: [[-1, -2]],
      l7: [[-2, 1]],
      l8: [[-2, -1]] }
  end
end

# superclass where first move matters
class FirstMovePiece < Piece
  attr_accessor :first_move

  def initialize(color:, row:, column:)
    @first_move = true
    super(color: color, row: row, column: column)
  end
end

# chess piece King
class King < FirstMovePiece
  def initials
    'K'
  end
end

# chess piece Pawn
class Pawn < FirstMovePiece
  def initials
    'P'
  end

  def all_moves
    result = super
    result[main_direction] += two_step if first_move
    result
  end

  def main_direction
    # :symbol (implement in subclass)
  end

  def two_step
    [] # implement this in subclass
  end

  def diagonals
    # implement this in subclass
  end

  def filter_moves(board)
    move_hash = moves_sums
    move_hash = filter_diagonals(board: board, move_hash: move_hash)
    move_hash = filter_two_steps(board: board, move_hash: move_hash)
    move_hash = filter_in_bounds(board: board, move_hash: move_hash)
    filter_blocked_path(board: board, move_hash: move_hash)
  end

  # private

  def filter_diagonals(board:, move_hash:)
    move_hash.each do |direction, moves|
      next unless diagonals.include?(direction)

      move = moves[0] # diagonal only one moves
      moves.delete(move) unless board.enemy?(obj: self, row: move[0], column: move[1])
    end
    move_hash
  end

  def filter_two_steps(board:, move_hash:)
    move_hash.each do |direction, moves|
      next unless main_direction == direction

      moves.each do |move|
        next unless two_step.include?(move)

        moves.delete(move) unless board.empty?(row: move[0], column: move[1])
      end
    end
    move_hash
  end
end

# Pawn piece for Player that move First
class FirstPlayerPawn < Pawn
  def move_directions
    %i[north
       north_east
       north_west]
  end

  def main_direction
    :north
  end

  def two_step
    [[2, 0]]
  end

  def diagonals
    %i[north_west
       north_east]
  end
end

# Pawn piece for Player move Second
class SecondPlayerPawn < Pawn
  def move_directions
    %i[south
       south_east
       south_west]
  end

  def two_step
    [[-2, 0]]
  end

  def diagonals
    %i[south_east
       south_west]
  end
end

# class that holds all Yellow pieces set, along with its starting row, column
# [[Piece, row, column], .., ..]
class ChessSet
  def set
    pawns + rooks + knights + bishops + queen + king
  end

  def color
    'insert color in subclass'
  end

  def pawn_class
    # insert corresponding Pawn class in the set
  end

  def non_pawn_row
    # insert corresponding non_pawn starting row position
  end

  def pawn_row
    # insert corresponding pawn starting row position
  end

  def pawns
    outer = []
    8.times do |column|
      pawn = pawn_class.new(color: color, row: pawn_row, column: column)
      outer.push([pawn, pawn_row, column])
    end
    outer
  end

  def two_piece(piece_class:, right_column_num:)
    outer = []
    left_column_num = 7 - right_column_num
    [left_column_num, right_column_num].each do |column|
      piece = piece_class.new(color: color, row: non_pawn_row, column: column)
      outer.push([piece, non_pawn_row, column])
    end
    outer
  end

  def rooks
    two_piece(piece_class: Rook, right_column_num: 7)
  end

  def knights
    two_piece(piece_class: Knight, right_column_num: 6)
  end

  def bishops
    two_piece(piece_class: Bishop, right_column_num: 5)
  end

  def queen
    column = 3
    queen = Queen.new(color: color, row: non_pawn_row, column: column)
    [[queen, non_pawn_row, column]]
  end

  def king
    column = 4
    king = King.new(color: color, row: non_pawn_row, column: column)
    [[king, non_pawn_row, column]]
  end
end

# the yellow set in the game
class Yellow < ChessSet
  def color
    'yellow'
  end

  def pawn_class
    FirstPlayerPawn
  end

  def non_pawn_row
    0
  end

  def pawn_row
    1
  end
end

# the Blue set in this game
class Blue < ChessSet
  def color
    'blue'
  end

  def pawn_class
    SecondPlayerPawn
  end

  def non_pawn_row
    7
  end

  def pawn_row
    6
  end
end

# A concrete class of ChessBoard
class ChessBoard < Board
  def initialize
    super(8)
    insert_pieces
  end

  def moves(row:, column:)
    piece = select(row: row, column: column)
    piece.filter_moves(self)
  end

  def insert_pieces
    insert_set(Yellow.new)
    insert_set(Blue.new)
  end

  def insert_set(chess_set_obj)
    chess_set_obj.set.each do |piece_arr|
      insert(board_piece: piece_arr[0], row: piece_arr[1], column: piece_arr[2])
    end
  end

  def empty?(row:, column:)
    piece = select(row: row, column: column)

    if piece.nil?
      true
    else
      false
    end
  end

  def enemy?(obj:, row:, column:)
    return false if empty?(row: row, column: column)

    tenant = select(row: row, column: column)
    tenant.color != obj.color
  end

  def ally?(piece:, row:, column:)
    return false if empty?(row: row, column: column)

    tenant = select(row: row, column: column)
    tenant.color == piece.color
  end
end

# class to handle Board displays
class BoardDisplay
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def show_board(to_display = @board)
    last = to_display.size - 1
    column_num = to_display.size
    last.downto(0) do |row_num|
      puts seperator(column_num) if row_num == 7
      puts row(to_display: to_display, row_num: row_num, column_num: column_num)
      puts seperator(column_num)
      puts column_index_row if row_num.zero?
    end
  end

  def show_moves(row:, column:)
    board_copy = copy(board)
    move_hash = board.moves(row: row, column: column)
    turn_enemies_red(board: board_copy, move_hash: move_hash)
    add_dots(board: board_copy, move_hash: move_hash)
    show_board(board_copy)
  end

  # translate input on the grid to board format
  def translate(input)
    input_arr = input.split('')
    y = input_arr[0]
    x = input_arr[1]
    [x.ord - 49, y.ord - 97]
  end

  def valid_input?(input)
    return false unless input.length == 2

    input_arr = input.split('')
    input_arr[0].between?('a', 'h') && input_arr[1].between?('1', '8')
  end

  # private
  def seperator(column_size)
    str = sep_str * column_size + '+'.colorize(mode: :bold)
    str.prepend('  ')
  end

  def sep_str
    '+---'.colorize(mode: :bold)
  end

  def row(to_display:, row_num:, column_num:)
    str = "#{row_num + 1} "
    column_num.times do |column|
      str += row_str(to_display: to_display, row: row_num, column: column)
    end
    str += '|'.colorize(mode: :bold)
  end

  def row_str(to_display:, row:, column:)
    element = to_display.select(row: row, column: column)
    '|'.colorize(mode: :bold) + " #{empty_or_piece(element)} "
  end

  def empty_or_piece(element)
    if element.nil?
      ' '
    else
      element
    end
  end

  def column_index_row
    str = ''
    ('A'..'H').each do |letter|
      str += "#{letter}   "
    end
    str.prepend('    ')
  end

  def copy(board)
    # deep copy
    serialized_board = Marshal.dump(board)
    Marshal.load(serialized_board)
  end

  def turn_enemies_red(board:, move_hash:)
    move_hash.each_value do |moves|
      next if moves.empty?

      moves.each do |move|
        next if board.empty?(row: move[0], column: move[1])

        piece = board.select(row: move[0], column: move[1])
        initials = piece.initials
        str = initials.colorize(:red)
        board.insert(board_piece: str, row: move[0], column: move[1])
      end
    end
  end

  def add_dots(board:, move_hash:)
    move_hash.each_value do |moves|
      next if moves.empty?

      moves.each do |move|
        next unless board.empty?(row: move[0], column: move[1])

        dot = "\u25cf"
        board.insert(board_piece: dot, row: move[0], column: move[1])
      end
    end
  end
end

# class to differentiate players
class Player
  attr_reader :name, :color

  def initialize(name:, color:)
    @name = name
    @color = color
  end
end

# emulates someone that organises the game, takes in input etc.
class ChessIO
  def intro
    'Welcome to Chess'
  end

  def ask_name
    print 'Enter your name: '
    gets.chomp
  end

  def ask_piece
    print 'Enter the piece you want to move: '
    gets.chomp
  end

  def error(type)
    { 'input' => 'The input given was invalid. Try again below.' }[type]
  end
end

# the game
class Chess
  attr_accessor :board
  attr_reader :io, :players, :display

  def initialize
    @board = ChessBoard.new
    @display = BoardDisplay.new(board)
    @io = ChessIO.new
    @players = add_players
  end

  def colors
    %w[yellow blue]
  end

  def add_players
    color_arr = colors
    players = []
    2.times do
      name = io.ask_name
      color = color_arr.delete(color_arr.sample)
      player = Player.new(name: name, color: color)
      players.push(player)
    end
    players
  end

  def ask_piece
    input = io.ask_piece
    until display.valid_input?(input)
      puts io.error('input')
      input = io.ask_piece
    end
    input
  end

  def input_piece?(input_str)
    input_arr = display.translate(input_str)
    !board.empty?(row: input_arr[0], column: input_arr[1])
  end

  def input_enemy?(player:, input_str:)
    input_arr = display.translate(input_str)
    board.enemy?(obj: player, row: input_arr[0], column: input_arr[1])
  end
end

chess = Chess.new
chess.ask_piece
