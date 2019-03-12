# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

from tictactoe import Game, HumanPlayer
from example_agents import RandomAgent, NaiveBestFirstAgent

def play_game(
        game,
        players=[
            HumanPlayer(),
            NaiveBestFirstAgent('X',smart_block=True)
            ],
        check_every_n_turns=500
        ):
    assert len(players) == 2, "Only two players"

    game.display_board()

    turn = 0
    while 1:
        for player in players:
            turn += 1
            print('-'*10,"Turn",turn,'-'*10)

            winner = game.take_turn(player.next_move(game))
            game.display_board()

            if winner == 'C':
                print("Cat's game...")
                return winner
            elif winner:
                print(winner,"is the winner!!!")
                return winner

if __name__ == "__main__":
    print("building game...",end=' ')
    g = Game(size=4,dim=9)
    print("done!")
    winners = list()

    for i in range(10):
        #w = play_game(g)
        #w = play_game(g,players=[RandomAgent(), RandomAgent()])
        #w = play_game(g,players=[RandomAgent(), NaiveBestFirstAgent('X')])
        w = play_game(g,players=[RandomAgent(), NaiveBestFirstAgent('X',smart_block=True)])
        g.new_game()
        winners.append(w)

    print(winners)
