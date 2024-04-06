# frozen_string_literal: true

require 'matrix'
# class that stores the pieces in the game
class Board
  attr_accessor :matrix

  def initialize(size)
    @matrix = Array.new(size).map { Array.new(size) }
  end

  def insert(board_piece:, row:, column:)
    matrix[row][column] = board_piece
  end
end

# rules of board and pieces that is specific to chess
class ChessContext
  def board_size
    8
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

  private

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
    2
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
