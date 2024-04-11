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

  # private

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
    all_vectors = []
    move_directions.each do |direction|
      vector = base_vectors(direction)
      vectors = max_range_vectors(vector, scalar)
      all_vectors.push(vectors.shift) until vectors.empty?
    end
    all_vectors
  end

  def initials
    # implement in subclass
  end

  def to_s
    initials.colorize(color.to_sym)
  end

  # private

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

  def scalar
    1
  end

  def vector_multiply(vector, multiplier)
    vector_product = []
    vector_product[0] = vector[0] * multiplier
    vector_product[1] = vector[1] * multiplier
    vector_product
  end

  def max_range_vectors(vector, scalar)
    product = []
    (1..scalar).to_a.each do |multiplier|
      vector_product = vector_multiply(vector, multiplier)
      product.push(vector_product)
    end
    product
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
    [[1, 2], [1, -2], [2, 1], [2, -1], [-1, 2], [-1, -2], [-2, 1], [-2, -1]]
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
    result += two_step if first_move
    result
  end

  def two_step
    [] # implement this in subclass
  end

  def diagonals
    [[]] # implement this in subclass
  end

  def diagonal?(move)
    diagonals.include?(move)
  end
end

# Pawn piece for Player that move First
class FirstPlayerPawn < Pawn
  def move_directions
    %i[north
       north_east
       north_west]
  end

  def two_step
    [[2, 0]]
  end

  def diagonals
    [[1, 1], [1, -1]]
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
    [[-1, 1], [1, -1]]
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
    move_array = piece_move_array(piece)
    after_move_array = coordinates_after_move(piece: piece, array: move_array)
    in_bound_moves = filter_out_of_bounds(after_move_array)
    filter_legit_moves(piece: piece, in_bound_moves: in_bound_moves)
  end

  # private

  def insert_pieces
    insert_set(Yellow.new)
    insert_set(Blue.new)
  end

  def insert_set(chess_set_obj)
    chess_set_obj.set.each do |piece_arr|
      insert(board_piece: piece_arr[0], row: piece_arr[1], column: piece_arr[2])
    end
  end

  def piece_move_array(piece)
    if piece.is_a? Pawn
      filter_pawn_enemy_diag(piece)
    else
      piece.all_moves
    end
  end

  def filter_pawn_enemy_diag(pawn)
    moves = pawn.all_moves.dup
    pawn.all_moves.each do |move|
      moves.delete(move) if pawn.diagonal?(move) && !enemy?(piece: pawn, row: move[0], column: move[1])
    end
    moves
  end

  def coordinates_after_move(piece:, array:)
    move_array = array.dup
    move_array.each do |move|
      move[0] += piece.row
      move[1] += piece.column
    end
    move_array
  end

  def filter_out_of_bounds(move_array)
    move_array.select { |move| move.all? { |i| i >= 0 && i < size } }
  end

  def filter_legit_moves(piece:, in_bound_moves:)
    in_bound_moves.select { |move| legit_move?(piece: piece, row: move[0], column: move[1]) }
  end

  def empty?(row:, column:)
    piece = select(row: row, column: column)

    if piece.nil?
      true
    else
      false
    end
  end

  def enemy?(piece:, row:, column:)
    return false if empty?(row: row, column: column)

    tenant = select(row: row, column: column)
    tenant.color != piece.color
  end

  def legit_move?(piece:, row:, column:)
    if empty?(row: row, column: column) || enemy?(piece: piece, row: row, column: column)
      true
    else
      false
    end
  end
end

# class to handle Board displays
class BoardDisplay
  attr_reader :board

  def initialize(board)
    @board = board
  end

  def sep_str
    '+---'.colorize(mode: :bold)
  end

  def row_str(row:, column:)
    element = board.select(row: row, column: column)
    '|'.colorize(mode: :bold) + " #{occupied?(element)} "
  end

  def occupied?(element)
    if element.nil?
      ' '
    else
      element
    end
  end

  def seperator(column_size = board.size)
    str = sep_str * column_size + '+'.colorize(mode: :bold)
    str.prepend('  ')
  end

  def row(row_num, column_num = board.size)
    str = "#{row_num + 1} "
    column_num.times do |column|
      str += row_str(row: row_num, column: column)
    end
    str += '|'.colorize(mode: :bold)
  end

  def column_index_row
    str = ''
    ('A'..'H').each do |letter|
      str += "#{letter}   "
    end
    str.prepend('    ')
  end

  def show_board
    8.times do |row_num|
      puts seperator if row_num.zero?
      puts row(row_num)
      puts seperator
      puts column_index_row if row_num == 7
    end
  end
end

board = ChessBoard.new
display = BoardDisplay.new(board)
queen = Queen.new(color: 'yellow', row: 0, column: 3)
display.show_board
