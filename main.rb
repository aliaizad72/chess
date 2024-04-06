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

# superclass chess pieces
class Piece
  attr_reader :color

  def initialize(color)
    @color = color
  end

  def moves
    [[1, 0], [-1, 0]]
  end
end
