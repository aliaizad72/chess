# frozen_string_literal: true

# the game
class Chess
  attr_accessor :board, :winner, :current_player
  attr_reader :io, :players, :display

  def initialize
    @board = ChessBoard.new
    @display = BoardDisplay.new(board)
    @io = ChessIO.new(board)
    @players = add_players
    @winner = nil
    @current_player = nil
  end

  def play
    io.intro
    io.instructions
    io.announce_colors(players)
    play_round
    announce_endgame
  end

  def announce_endgame
    if winner
      announce_winner
    else
      announce_stalemate
    end
  end

  def announce_stalemate
    display.show_board
    io.announce_stalemate
  end

  # private

  def play_round
    until endgame?
      players.each do |player|
        player.winner = false if board.checkmate?(player)

        break if endgame?

        @current_player = player
        display.show_board
        io.announce_turn(player)
        if move(player) == 'save'
          save
          exit 0
        end
        board.promotion
        check_if_checked(player)
      end
    end

    @winner = players.find(&:winner) if checkmate?
  end

  def announce_winner
    display.show_board
    io.announce_winner(winner)
  end

  def checkmate?
    board.checkmate?(players[0]) || board.checkmate?(players[1])
  end

  def stalemate?
    board.stalemate?(players[0]) || board.stalemate?(players[1])
  end

  def endgame?
    checkmate? || stalemate?
  end

  def move(player)
    io.error('check') if board.checked?(player)
    input = io.ask_and_confirm(player)
    return input if input == 'save'

    move_input = io.ask_move(input)
    piece = display.translate(input)
    move = display.translate(move_input)
    board.move(from_row: piece[0], from_column: piece[1], to_row: move[0], to_column: move[1])
  end

  def save
    current_game = YAML.dump(self)
    Dir.mkdir('saved_games') unless Dir.exist?('saved_games')
    filename = io.ask('filename')
    path = "saved_games/#{filename}.yaml"
    File.open(path, 'w') { |file| file.write(current_game) }
    puts 'Your game has been saved. Exiting the program.'
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
