# frozen_string_literal: true

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

  def moves_sums(hash: all_moves, row: @row, column: @column)
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

  def update(row:, column:)
    @row = row
    @column = column
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

      if board.enemy?(colored_obj: self, row: move[0], column: move[1])
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

  def opposite_direction(direction)
    { north: :south,
      north_east: :south_west,
      east: :west,
      south_east: :north_west,
      south: :north,
      south_west: :north_east,
      west: :east,
      north_west: :south_east }[direction]
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

# chess piece Queen
class Queen < Piece
  def initials
    'Q'
  end

  def scalar
    7
  end
end

# pieces that is needed for castling
class CastlingPiece < Piece
  attr_accessor :first_move

  def initialize(color:, row:, column:)
    @first_move = nil
    super(color: color, row: row, column: column)
  end

  def update(row:, column:)
    super(row: row, column: column)
    @first_move = if first_move.nil?
                    true
                  else
                    false
                  end
  end
end

# chess piece Rook
class Rook < CastlingPiece
  def initials
    'R'
  end

  def move_directions
    %i[north
       south
       west
       east]
  end

  def scalar
    7
  end
end

# chess piece Bishop
class Bishop < Piece
  def initials
    'B'
  end

  def move_directions
    %i[north_east
       north_west
       south_east
       south_west]
  end

  def scalar
    7
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

# chess piece King
class King < CastlingPiece
  def initials
    'K'
  end

  def castling_conditions(path:, board:, rook_col:)
    piece = board.select(row: row, column: rook_col)
    first_move && check_rook?(piece) && check_first_move?(piece) && check_path_unblocked?(path: path,
                                                                                          board: board) && check_path_unattacked?(
                                                                                            path: path, board: board
                                                                                          )
  end

  def add_castling(board:, move_hash:)
    return move_hash if checked?(board)

    move_hash = filter_left_castling(board: board, move_hash: move_hash)
    filter_right_castling(board: board, move_hash: move_hash)
  end

  def filter_left_castling(board:, move_hash:)
    return move_hash unless left_castling_conditions(board)

    move_hash.merge({ left_castling: [[row, column - 2]] })
  end

  def filter_right_castling(board:, move_hash:)
    return move_hash unless right_castling_conditions(board)

    move_hash.merge({ right_castling: [[row, column + 2]] })
  end

  def right_castling_conditions(board)
    castling_conditions(path: [5, 6], board: board, rook_col: 7)
  end

  def left_castling_conditions(board)
    castling_conditions(path: [2, 3], board: board, rook_col: 0)
  end

  def check_rook?(piece)
    return false unless piece.is_a? Rook

    true
  end

  def check_first_move?(rook)
    rook.first_move
  end

  def check_path_unattacked?(path:, board:)
    path.each do |col|
      return false if attacked?(board: board, row: row, column: col)
    end
    true
  end

  def checked?(board)
    attacked?(board: board, row: row, column: column)
  end

  def attacked?(board:, row:, column:)
    non_knight_attack?(board: board, row: row, column: column) || knight_attack?(board: board, row: row, column: column)
  end

  def check_path_unblocked?(path:, board:)
    path.each do |col|
      return false unless board.empty?(row: row, column: col)
    end
    true
  end

  def knight_attack
    { knight: [[1, 2], [1, -2], [2, 1], [2, -1], [-1, 2], [-1, -2], [-2, 1], [-2, -1]] }
  end

  def attacked_vectors
    all_vectors = {}
    move_directions.each do |direction|
      vector = base_vectors(direction)
      vectors = max_range_vectors(vector, 7)
      all_vectors[direction] = vectors
    end
    all_vectors.merge(knight_attack)
  end

  def attacked_vectors_sums(board:, row:, column:)
    hash = moves_sums(hash: attacked_vectors, row: row, column: column)
    filter_in_bounds(board: board, move_hash: hash)
  end

  def filter_enemy_in_path(board:, row:, column:)
    hash = attacked_vectors_sums(board: board, row: row, column: column)
    hash.delete(:knight) # knight is not affected by path attack
    hash.each do |direction, moves|
      next if moves.empty?

      hash[direction] = if enemy_in_path?(board: board, moves: moves)
                          moves[find_enemy_index(board: board, moves: moves)]
                        else
                          []
                        end
    end
    hash
  end

  def enemy_in_path?(board:, moves:)
    moves.each do |move|
      return true if board.enemy?(colored_obj: self, row: move[0], column: move[1])

      return false if board.ally?(piece: self, row: move[0], column: move[1])
    end
    false
  end

  def find_enemy_index(board:, moves:)
    moves.each do |move|
      return moves.index(move) if board.enemy?(colored_obj: self, row: move[0], column: move[1])
    end
  end

  def non_knight_attack?(board:, row:, column:)
    hash = filter_enemy_in_path(board: board, row: row, column: column)
    hash = hash.reject { |_direction, moves| moves.empty? }
    return false if hash.empty?

    attacked_coordinates = [row, column]
    hash.each do |direction, coordinates|
      next if %i[right_castling left_castling].include?(direction)

      piece = board.select(row: coordinates[0], column: coordinates[1])
      piece_moves = piece.filter_moves(board)
      attack_direction = opposite_direction(direction)
      next if piece_moves[attack_direction].nil?

      return true if piece_moves[attack_direction].include?(attacked_coordinates)
    end
    false
  end

  def knight_attack?(board:, row:, column:)
    hash = attacked_vectors_sums(board: board, row: row, column: column)
    hash[:knight].each do |move|
      next unless board.select(row: move[0], column: move[1]).is_a? Knight

      return true if board.enemy?(colored_obj: self, row: move[0], column: move[1])
    end
    false
  end
end

# chess piece Pawn
class Pawn < Piece
  def initials
    'P'
  end

  def all_moves
    result = super
    result[main_direction] += two_step if row == starting_row
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

  def starting_row
    # implement this in subclass
  end

  def promotion_row
    # implement this in subclass
  end

  def distance(loc_one, loc_two)
    (loc_one - loc_two).abs
  end

  def distance_from_start
    distance(row, starting_row)
  end

  def en_passant_row(piece)
    # implement this in subclass
  end

  def filter_en_passant(board:, move_hash:)
    return move_hash unless board.last_move

    piece = board.last_move[:moved]
    last_row = board.last_move[:from][0]
    move = if en_passant?(piece: piece, last_row: last_row)
             [[en_passant_row(piece), piece.column]]
           else
             []
           end
    move_hash.merge({ en_passant: move })
  end

  def en_passant?(piece:, last_row:)
    distance_from_start >= 3 && piece.is_a?(Pawn) && color != piece.color && distance(row,
                                                                                      last_row) == 2 && distance(
                                                                                        column, piece.column
                                                                                      ) == 1
  end

  def filter_moves(board, move_hash = moves_sums)
    move_hash = filter_diagonals(board: board, move_hash: move_hash)
    move_hash = filter_forwards(board: board, move_hash: move_hash)
    move_hash = filter_en_passant(board: board, move_hash: move_hash)
    move_hash = filter_in_bounds(board: board, move_hash: move_hash)
    filter_blocked_path(board: board, move_hash: move_hash)
  end

  # private

  def filter_diagonals(board:, move_hash:)
    move_hash.each do |direction, moves|
      next unless diagonals.include?(direction)

      move = moves[0] # diagonal only one moves
      moves.delete(move) unless board.enemy?(colored_obj: self, row: move[0], column: move[1])
    end
    move_hash
  end

  def filter_forwards(board:, move_hash:)
    move_hash.each do |direction, moves|
      next unless main_direction == direction

      moves.each do |move|
        moves.delete(move) unless board.empty?(row: move[0], column: move[1])
      end
    end
    move_hash
  end
end

# Pawn piece for Player that move First
class FirstPlayerPawn < Pawn
  def starting_row
    1
  end

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

  def en_passant_row(piece)
    piece.row + 1
  end

  def en_pass_attack_row
    row - 1
  end

  def promotion_row
    7
  end
end

# Pawn piece for Player move Second
class SecondPlayerPawn < Pawn
  def starting_row
    6
  end

  def move_directions
    %i[south
       south_east
       south_west]
  end

  def main_direction
    :south
  end

  def two_step
    [[-2, 0]]
  end

  def diagonals
    %i[south_east
       south_west]
  end

  def en_passant_row(piece)
    piece.row - 1
  end

  def en_pass_attack_row
    row + 1
  end

  def promotion_row
    0
  end
end
