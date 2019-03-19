# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

from tictactoe import Game, HumanPlayer
from agents import NaiveBestFirstAgent, RandomAgent, ReinforcementAgent


def play_game(game, players):
    assert len(players) == 2, 'Only two players'

    game.display_board()

    turn = 0
    while 1:
        for player in players:
            turn += 1
            print(f'Turn {turn}'.center(28, '-'))

            winner = game.take_turn(player.next_move(game))
            game.display_board()

            if winner == 'C':
                print("Cat's game...")
                return winner
            elif winner:
                print(winner, 'is the winner!!!')
                return winner

if __name__ == '__main__':
    print('Building game...', end=' ', flush=True)
    game = Game(size=4, dim=3)
    print('done!')
    players = [ReinforcementAgent(b'O'), NaiveBestFirstAgent(b'X')]
    winners = []

    for i in range(10):
        game.new_game()
        winner = play_game(game, players=players)
        game.new_game()
        winners.append(winner)

    print(winners)
