# frozen_string_literal: true

# class that holds all Yellow pieces set, along with its starting row, column
# [[Piece, row, column], .., ..]
class ChessSet
  def set
    pawns + rooks + queen + king + knights + bishops
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
