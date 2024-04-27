# frozen_string_literal: true

# class that stores the pieces in the game
class Board
  attr_accessor :array, :last_move
  attr_reader :size

  def initialize(size)
    @size = size
    @array = Array.new(size).map { Array.new(size) }
    @last_move = nil
  end

  def insert(board_piece:, row:, column:)
    array[row][column] = board_piece
    board_piece.update(row: row, column: column) if board_piece.is_a? Piece
  end

  def move(from_row:, from_column:, to_row:, to_column:)
    to_move = select(row: from_row, column: from_column)
    to_delete = select(row: to_row, column: to_column)
    remove(row: from_row, column: from_column)
    insert(board_piece: to_move, row: to_row, column: to_column)
    @last_move = { moved: to_move,
                   deleted: to_delete,
                   moved_coordinates: [to_row, to_column],
                   from: [from_row, from_column],
                   en_passant?: false }
  end

  def unmove
    current = last_move[:moved_coordinates]
    previous = last_move[:from]
    deleted = last_move[:deleted]
    move(from_row: current[0], from_column: current[1], to_row: previous[0], to_column: previous[1])
    insert(board_piece: deleted, row: current[0], column: current[1])
  end

  def select(row:, column:)
    array[row][column]
  end

  def remove(row:, column:)
    array[row][column] = nil
  end

  def copy
    serialised = Marshal.dump(self)
    Marshal.load(serialised)
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
    move_hash = piece.filter_moves(self)
    move_hash = filter_checked_moves(piece, move_hash)
    move_hash = piece.add_castling(board: self, move_hash: move_hash) if piece.is_a?(King)
    move_hash.reject { |_direction, moves| moves.empty? }
  end

  def insert_pieces
    # insert_set(Yellow.new)
    # insert_set(Blue.new)
    king = King.new(color: 'blue', row: 7, column: 4)
    insert(board_piece: king, row: king.row, column: king.column)
    enemy_king = King.new(color: 'yellow', row: 0, column: 4)
    insert(board_piece: enemy_king, row: enemy_king.row, column: enemy_king.column)

    # bishop = Bishop.new(color: 'yellow', row: 5, column: 7)
    # insert(board_piece: bishop, row: bishop.row, column: bishop.column)

    # rook_one = Rook.new(color: 'blue', row: 7, column: 7)
    # insert(board_piece: rook_one, row: rook_one.row, column: rook_one.column)
    # rook_two = Rook.new(color: 'blue', row: 7, column: 0)
    # insert(board_piece: rook_two, row: rook_two.row, column: rook_two.column)

    pawn = FirstPlayerPawn.new(color: 'yellow', row: 6, column: 0)
    insert(board_piece: pawn, row: pawn.row, column: pawn.column)

    # enemy_pawn = FirstPlayerPawn.new(color: 'yellow', row: 3, column: 0)
    # insert(board_piece: enemy_pawn, row: enemy_pawn.row, column: enemy_pawn.column)

    # enemy_queen = Queen.new(color: 'blue', row: 7, column: 6)
    # insert(board_piece: enemy_queen, row: enemy_queen.row, column: enemy_queen.column)

    # queen_block_pawn = FirstPlayerPawn.new(color: 'yellow', row: 3, column: 2)
    # insert(board_piece: queen_block_pawn, row: queen_block_pawn.row, column: queen_block_pawn.column)

    # enemy_knight = Knight.new(color: 'yellow', row: 0, column: 2)
    # insert(board_piece: enemy_knight, row: enemy_knight.row, column: enemy_knight.column)
  end

  def move(from_row:, from_column:, to_row:, to_column:)
    if en_passant_move?(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      super(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      en_passant(to_row: to_row, to_column: to_column)
    elsif right_castling_move?(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      super(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      rook_row = to_row
      rook_column = to_column + 1
      super(from_row: rook_row, from_column: rook_column, to_row: rook_row, to_column: rook_column - 2)
    elsif left_castling_move?(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      super(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
      rook_row = to_row
      rook_column = to_column - 2
      super(from_row: rook_row, from_column: rook_column, to_row: rook_row, to_column: rook_column + 3)
    else
      super(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column)
    end
  end

  def unmove
    if last_move[:en_passant?]
      deleted = last_move[:deleted]
      insert(board_piece: deleted, row: deleted.row, column: deleted.column)
      @last_move[:deleted] = nil
      @last_move[:en_passant?] = false
    end

    super
  end

  def promotion
    piece = last_move[:moved]
    return unless piece.is_a?(Pawn) && last_move[:moved_coordinates][0] == piece.promotion_row

    piece_class = ask_class
    new_piece = piece_class.new(color: piece.color, row: piece.row, column: piece.column)
    insert(board_piece: new_piece, row: new_piece.row, column: new_piece.column)
  end

  def ask_class
    puts "Enter the first letter of the piece you want your pawn to upgrade to? e.g 'Q' for Queen."
    print 'First letter: '
    input = gets.chomp
    to_class(input)
  end

  def to_class(input)
    case input
    when 'R'
      Rook
    when 'B'
      Bishop
    when 'N'
      Knight
    else
      Queen
    end
  end

  def castling_move?(from_row:, from_column:, to_row:, to_column:, column_diff:)
    to_move = select(row: from_row, column: from_column)
    diff = from_column - to_column

    to_move.is_a?(King) && diff == column_diff
  end

  def right_castling_move?(from_row:, from_column:, to_row:, to_column:)
    castling_move?(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column, column_diff: -2)
  end

  def left_castling_move?(from_row:, from_column:, to_row:, to_column:)
    castling_move?(from_row: from_row, from_column: from_column, to_row: to_row, to_column: to_column, column_diff: 2)
  end

  def en_passant(to_row:, to_column:)
    pawn = select(row: to_row, column: to_column)
    delete_row = pawn.en_pass_attack_row
    delete_col = pawn.column
    to_delete = select(row: delete_row, column: delete_col)
    remove(row: delete_row, column: delete_col)
    @last_move[:deleted] = to_delete
    @last_move[:en_passant?] = true
  end

  def en_passant_move?(from_row:, from_column:, to_row:, to_column:)
    to_move = select(row: from_row, column: from_column)
    column_diff = (from_column - to_column).abs

    to_move.is_a?(Pawn) && empty?(row: to_row, column: to_column) && column_diff == 1
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

  def checked?(colored_obj)
    select_king(colored_obj).checked?(self)
  end

  def all_pieces(colored_obj)
    pieces = array.flatten.reject(&:nil?)
    pieces.select { |piece| piece.color == colored_obj.color }
  end

  def select_king(colored_obj)
    pieces = all_pieces(colored_obj)
    pieces.select { |piece| piece.is_a? King }[0]
  end

  def enemy?(colored_obj:, row:, column:)
    return false if empty?(row: row, column: column)

    tenant = select(row: row, column: column)
    tenant.color != colored_obj.color
  end

  def ally?(piece:, row:, column:)
    return false if empty?(row: row, column: column)

    tenant = select(row: row, column: column)
    tenant.color == piece.color
  end

  def filter_checked_moves(piece, move_hash)
    board_copy = copy

    move_hash.each do |direction, moves|
      filtered = []
      moves.each do |move|
        board_copy.move(from_row: piece.row, from_column: piece.column, to_row: move[0], to_column: move[1])
        filtered.push(move) unless board_copy.checked?(piece)
        board_copy.unmove
      end
      move_hash[direction] = filtered
    end
    move_hash
  end

  def no_moves_left?(player)
    pieces = all_pieces(player)
    pieces_moves = pieces.map { |piece| moves(row: piece.row, column: piece.column) }
    pieces_moves = pieces_moves.reject(&:empty?)
    pieces_moves.empty?
  end

  def checkmate?(player)
    return false unless checked?(player)

    board_copy = copy
    pieces = board_copy.all_pieces(player)
    pieces.each do |piece|
      piece_moves = board_copy.moves(row: piece.row, column: piece.column)
      piece_moves.each_value do |moves|
        moves.each do |move|
          board_copy.move(from_row: piece.row, from_column: piece.column, to_row: move[0], to_column: move[1])
          return false unless board_copy.checked?(player)

          board_copy.unmove
        end
      end
    end
    true
  end

  def stalemate?(player)
    return false if checked?(player)

    no_moves_left?(player)
  end
end
