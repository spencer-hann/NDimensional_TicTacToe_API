from tictactoe import Game
from example_agents import RandomAgent, NaiveBestFirstAgent

def two_player_game(g):
    g.display_board()

    turn = 0
    while 1:
        turn += 1
        print('-'*10,"Turn",turn,'-'*10)
        winner = g.take_turn()
        g.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

def human_vs_ai_game(game,ai):
    game.display_board()

    turn = 0
    while 1:
        turn += 1
        print('-'*10,"Turn",turn,'-'*10)
        winner = game.take_turn() # for user
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

        winner = game.take_turn(ai.next_move(game))
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

def ai_vs_ai_game(game,ai1,ai2):
    game.display_board()

    turn = 0
    while 1:
        turn += 1
        print('-'*10,"Turn",turn,'-'*10)
        winner = game.take_turn(ai1.next_move(game))
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

        winner = game.take_turn(ai2.next_move(game))
        print() # new line
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break


if __name__ == "__main__":
    print("building game...",end=' ')
    g = Game(size=4,dim=3)
    print("done!")
    #human_vs_ai_game(g,RandomAgent())
    #ai_vs_ai_game(g,RandomAgent(), NaiveBestFirstAgent('X'))
    ai_vs_ai_game(g,RandomAgent(), NaiveBestFirstAgent('X',smart_block=True))
