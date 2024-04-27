# frozen_string_literal: true

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

  def announce_stalemate
    puts 'Game ends in a stalemate. Nobody wins.'
  end

  def ask_and_confirm(player)
    confirm = 'n'
    until confirm == 'y'
      input = ask_piece(player)
      return input if input == 'save'

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
    return input if input == 'save'

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
      'move' => 'Enter the destination coordinates: ',
      'filename' => 'Enter your preferred filename for this save: ' }[type]
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
