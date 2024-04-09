# frozen_string_literal: true

# class that stores the pieces in the game
class Board
  attr_accessor :array

  def initialize(size)
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

  private

  def select(row:, column:)
    array[row][column]
  end

  def remove(row:, column:)
    array[row][column] = nil
  end
end

# superclass chess pieces
class Piece
  attr_reader :color

  def initialize(color)
    @color = color
  end

  def moves
    # array with each possible vector
    all_vectors = []
    move_directions.each do |direction|
      vector = base_vectors(direction)
      vectors = max_range_vectors(vector, scalar)
      all_vectors.push(vectors.shift) until vectors.empty?
    end
    all_vectors
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
end

# chess piece Rook
class Rook < SevenStepPiece
  def move_directions
    %i[north
       south
       west
       east]
  end
end

# chess piece Bishop
class Bishop < SevenStepPiece
  def move_directions
    %i[north_east
       north_west
       south_east
       south_west]
  end
end

# chess piece Knight
class Knight < Piece
  def moves
    [[1, 2], [1, -2], [2, 1], [2, -1], [-1, 2], [-1, -2], [-2, 1], [-2, -1]]
  end
end

# superclass where first move matters
class FirstMovePiece < Piece
  attr_accessor :first_move

  def initialize(color)
    @first_move = true
    super(color)
  end
end

# chess piece King
class King < FirstMovePiece
end

# chess piece Pawn
class Pawn < FirstMovePiece
  def moves
    result = super
    result += two_step if first_move
    result
  end

  def two_step
    []
  end
end

# chess piece YellowPawn
class YellowPawn < Pawn
  def initialize
    super('yellow')
  end

  def move_directions
    %i[north
       north_east
       north_west]
  end

  def two_step
    [[2, 0]]
  end
end

# chess piece BluePawn
class BluePawn < Pawn
  def initialize
    super('blue')
  end

  def move_directions
    %i[south
       south_east
       south_west]
  end

  def two_step
    [[-2, 0]]
  end
end
