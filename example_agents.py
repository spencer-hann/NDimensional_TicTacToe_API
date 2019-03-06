from tictactoe import Game
import numpy as np

class RandomAgent:
    def __init__(self):
        pass # very simple agent, no internal state

    def next_move(self, game):
        while True:
            coord = tuple(np.random.randint(0,game.size,size=game.dim))
            if game.board[coord] == game.empty_square:
                return coord
