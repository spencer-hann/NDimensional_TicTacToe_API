from tictactoe import Game
from example_agents import RandomAgent

def two_player_game(g):
    print("building game...",end=' ')
    g.display_board()
    print("done!")

    turn = 0
    while 1:
        turn += 1
        print("Turn",turn)
        print('-'*20)
        winner = g.take_turn()
        g.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

def human_vs_ai_game(game,ai):
    print("building game...",end=' ')
    game.display_board()
    print("done!")

    turn = 0
    while 1:
        turn += 1
        print("Turn",turn)
        print('-'*20)
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
    print("building game...",end=' ')
    game.display_board()
    print("done!")

    turn = 0
    while 1:
        turn += 1
        print("\nTurn",turn)
        print('-'*20)
        winner = game.take_turn(ai1.next_move(game))
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break

        winner = game.take_turn(ai2.next_move(game))
        game.display_board()
        if winner:
            print(winner,"is the winner!!!")
            break


if __name__ == "__main__":
    g = Game(size=3,dim=3)
    human_vs_ai_game(g,RandomAgent())
    #ai_vs_ai_game(g,RandomAgent(),RandomAgent())
