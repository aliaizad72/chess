# frozen_string_literal: true

require 'colorize'
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
    occupant = select(row: to_row, column: to_column)
    remove(row: from_row, column: from_column)
    insert(board_piece: to_move, row: to_row, column: to_column)
    @last_move = { last_occupant: occupant, coordinates: [to_row, to_column], from: [from_row, from_column] }
  end

  def unmove
    current = last_move[:coordinates]
    previous = last_move[:from]
    last_occupant = last_move[:last_occupant]
    move(from_row: current[0], from_column: current[1], to_row: previous[0], to_column: previous[1])
    insert(board_piece: last_occupant, row: current[0], column: current[1])
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

  def moves_sums(hash = all_moves)
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

  def attacked_vectors_sums
    moves_sums(attacked_vectors)
  end

  def possible_attacked_coordinates(board)
    filter_in_bounds(board: board, move_hash: attacked_vectors_sums)
  end

  def filter_enemy_in_path(board)
    hash = possible_attacked_coordinates(board)
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

  def non_knight_attack?(board)
    hash = filter_enemy_in_path(board)
    hash = hash.reject { |_direction, moves| moves.empty? }
    return false if hash.empty?

    king_coordinates = [row, column]
    hash.each do |direction, coordinates|
      piece = board.select(row: coordinates[0], column: coordinates[1])
      piece_moves = piece.filter_moves(board)
      attack_direction = opposite_direction(direction)
      next if piece_moves[attack_direction].nil?

      return true if piece_moves[attack_direction].include?(king_coordinates)
    end
    false
  end

  def knight_attack?(board)
    possible_attacked_coordinates(board)[:knight].each do |move|
      next unless board.select(row: move[0], column: move[1]).is_a? Knight

      return true if board.enemy?(colored_obj: self, row: move[0], column: move[1])
    end
    false
  end

  def checked?(board)
    non_knight_attack?(board) || knight_attack?(board)
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

  def filter_moves(board, move_hash = moves_sums)
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
      moves.delete(move) unless board.enemy?(colored_obj: self, row: move[0], column: move[1])
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
    move_hash = piece.filter_moves(self)
    move_hash.reject { |_direction, moves| moves.empty? }
  end

  def insert_pieces
    insert_set(Yellow.new)
    insert_set(Blue.new)
    # king = King.new(color: 'yellow', row: 0, column: 4)
    # insert(board_piece: king, row: king.row, column: king.column)
    # enemy_king = King.new(color: 'blue', row: 7, column: 4)
    # insert(board_piece: enemy_king, row: enemy_king.row, column: enemy_king.column)

    # rook_one = Rook.new(color: 'blue', row: 0, column: 6)
    # insert(board_piece: rook_one, row: rook_one.row, column: rook_one.column)
    # rook_two = Rook.new(color: 'blue', row: 2, column: 7)
    # insert(board_piece: rook_two, row: rook_two.row, column: rook_two.column)

    # pawn = FirstPlayerPawn.new(color: 'yellow', row: 3, column: 2)
    # insert(board_piece: pawn, row: pawn.row, column: pawn.column)

    # enemy_pawn = SecondPlayerPawn.new(color: 'blue', row: 4, column: 3)
    # insert(board_piece: enemy_pawn, row: enemy_pawn.row, column: enemy_pawn.column)

    # enemy_queen = Queen.new(color: 'blue', row: 5, column: 6)
    # insert(board_piece: enemy_queen, row: enemy_queen.row, column: enemy_queen.column)

    # queen_block_pawn = FirstPlayerPawn.new(color: 'yellow', row: 4, column: 5)
    # insert(board_piece: queen_block_pawn, row: queen_block_pawn.row, column: queen_block_pawn.column)

    # enemy_knight = Knight.new(color: 'blue', row: 5, column: 5)
    # insert(board_piece: enemy_knight, row: enemy_knight.row, column: enemy_knight.column)
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

  def checked?(player)
    select_king(player).checked?(self)
  end

  def all_pieces(player)
    pieces = array.flatten.reject(&:nil?)
    pieces.select { |piece| piece.color == player.color }
  end

  def select_king(player)
    pieces = all_pieces(player)
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

  def mate?(player)
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
    board_copy = board.copy
    move_hash = board.moves(row: row, column: column)
    turn_enemies_red(board: board_copy, move_hash: move_hash)
    add_dots(board: board_copy, move_hash: move_hash)
    show_board(board_copy)
  end

  # translate input on the grid to board format
  def translate(input)
    input_arr = input.split('')
    y = input_arr[0].downcase
    x = input_arr[1]
    [x.ord - 49, y.ord - 97]
  end

  def valid_input?(input)
    return false unless input.length == 2

    input_arr = input.split('')
    input_arr[0].downcase.between?('a', 'h') && input_arr[1].between?('1', '8')
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
  attr_accessor :winner
  attr_reader :name, :color

  def initialize(name:, color:)
    @name = name
    @color = color
    @winner = true
  end
end

# emulates someone that organises the game, takes in input etc.
class ChessIO
  attr_reader :display, :board

  def initialize(board)
    @board = board
    @display = BoardDisplay.new(board)
  end

  def intro
    puts 'Welcome to Chess'
  end

  def instructions
    puts "To select a piece, enter coordinates. For example, 'a2' for yellow Knight."
  end

  def announce_colors(player_array)
    player_one = player_array[0]
    player_two = player_array[1]
    puts "#{player_one.name}, you are yellow. #{player_two.name}, you are blue."
  end

  def announce_turn(player)
    puts "#{player.name}, it is your turn."
  end

  def announce_winner(player)
    puts "Checkmate! #{player.name}, you won!"
  end

  def ask_and_confirm(player)
    confirm = 'n'
    until confirm == 'y'
      input = ask_piece(player)
      coordinates = display.translate(input)
      display.show_moves(row: coordinates[0], column: coordinates[1])
      confirm = ask('confirm')
    end
    input
  end

  def ask_move(piece_input)
    move_input = ask('move')
    move_input = check_valid_input(input: move_input, ask_method: 'move')
    check_piece_movable(piece_input: piece_input, move_input: move_input)
  end

  def ask_name
    ask('name')
  end

  # private
  def ask_piece(player)
    input = ask('piece_input')
    input = check_valid_input(input: input, ask_method: 'piece_input')
    input = check_input_piece(input)
    input = check_input_enemy(player: player, input: input)
    check_input_moves(player: player, input: input)
  end

  def ask(type)
    print ask_prompts(type)
    gets.chomp
  end

  def ask_prompts(type)
    { 'name' => 'Enter your name: ',
      'piece_input' => 'Enter the piece you want to move: ',
      'confirm' => 'Is this the piece you wanted to select? y/n: ',
      'move' => 'Enter the destination coordinates: ' }[type]
  end

  def check_valid_input(input:, ask_method:)
    until display.valid_input?(input)
      error('input')
      input = ask(ask_method)
    end
    input
  end

  def error(type)
    str = { 'input' => 'The input given was invalid. Try again below.',
            'piece' => 'The input given has nothing on it. Try again below.',
            'enemy' => 'That is not yours to move. Try again below.',
            'no_moves' => 'This piece currently has no moves. Try again below.',
            'not_movable' => 'The piece cannot move there. Try again below',
            'move_check' => 'That move will put you in check. Try again below.',
            'check' => 'You are in check.' }[type]
    puts str
  end

  def check_input_piece(input)
    until input_piece?(input)
      error('piece')
      input = ask('piece_input')
      input = check_valid_input(input: input, ask_method: 'piece_input')
    end
    input
  end

  def input_piece?(input)
    input_arr = display.translate(input)
    !board.empty?(row: input_arr[0], column: input_arr[1])
  end

  def check_input_enemy(player:, input:)
    while input_enemy?(player: player, input: input)
      error('enemy')
      input = ask('piece_input')
      input = check_valid_input(input: input, ask_method: 'piece_input')
      input = check_input_piece(input)
    end
    input
  end

  def input_enemy?(player:, input:)
    input_arr = display.translate(input)
    board.enemy?(colored_obj: player, row: input_arr[0], column: input_arr[1])
  end

  def check_input_moves(player:, input:)
    until piece_moves?(input)
      error('no_moves')
      input = ask('piece_input')
      input = check_valid_input(input: input, ask_method: 'piece_input')
      input = check_input_piece(input)
      input = check_input_enemy(player: player, input: input)
    end
    input
  end

  def piece_moves?(input)
    input_arr = display.translate(input)
    !board.moves(row: input_arr[0], column: input_arr[1]).empty?
  end

  def check_piece_movable(piece_input:, move_input:)
    until movable?(piece_input: piece_input, move_input: move_input)
      error('not_movable')
      move_input = ask('move')
      move_input = check_valid_input(input: move_input, ask_method: 'move')
    end
    move_input
  end

  def movable?(piece_input:, move_input:)
    piece_coordinates = display.translate(piece_input)
    move_coordinates = display.translate(move_input)
    move_hash = board.moves(row: piece_coordinates[0], column: piece_coordinates[1])
    move_hash.each_value do |moves|
      return true if moves.include?(move_coordinates)
    end
    false
  end
end

# the game
class Chess
  attr_accessor :board, :winner
  attr_reader :io, :players, :display

  def initialize
    @board = ChessBoard.new
    @display = BoardDisplay.new(board)
    @io = ChessIO.new(board)
    @players = add_players
    @winner = nil
  end

  def play
    io.intro
    io.instructions
    io.announce_colors(players)
    play_round
    announce_winner
  end

  # private

  def play_round
    until mate
      players.each do |player|
        if board.mate?(player)
          player.winner = false
          break
        end

        display.show_board
        io.announce_turn(player)
        move(player)
        check_if_checked(player)
      end
    end

    @winner = players.find(&:winner)
  end

  def announce_winner
    display.show_board
    io.announce_winner(winner)
  end

  def mate
    board.mate?(players[0]) || board.mate?(players[1])
  end

  def move(player)
    io.error('check') if board.checked?(player)
    input = io.ask_and_confirm(player)
    move_input = io.ask_move(input)
    piece = display.translate(input)
    move = display.translate(move_input)
    board.move(from_row: piece[0], from_column: piece[1], to_row: move[0], to_column: move[1])
  end

  def check_if_checked(player)
    while board.checked?(player)
      io.error('move_check')
      board.unmove
      display.show_board
      move(player)
    end
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
    sort_players(players)
  end

  def colors
    %w[yellow blue]
  end

  def sort_players(player_array)
    player_array.sort_by(&:color).reverse!
  end
end

chess = Chess.new
chess.play
