# frozen_string_literal: true

require 'colorize'
require 'yaml'
require_relative './board'
require_relative './piece'
require_relative './set'
require_relative './display'
require_relative './chess'

# class to differentiate players
class Player
  attr_accessor :winner
  attr_reader :name, :color

  def initialize(name:, color:)
    @name = name
    @color = color
    @winner = true
  end
end

chess = Chess.new
chess.play
# board = chess.board
# player = chess.players[0]
# king = board.select_king(player)
# p king.right_castling_conditions(board)
