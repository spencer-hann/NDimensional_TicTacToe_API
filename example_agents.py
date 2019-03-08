from tictactoe import Game
import numpy as np

class RandomAgent:
    def __init__(self):
        pass # very simple agent, no internal state

    def next_move(self, game):
        for i in range(100): # eventually just give up
            coord = tuple(np.random.randint(0,game.size,size=game.dim))
            if game.is_empty_here(coord):
                break
        return coord

class NaiveBestFirstAgent:
    def __init__(self, marker, smart_block=False):
        self.marker = marker
        self.smart_block = smart_block

    def next_move(self, game):
        best_endpair = None
        best_score = 0

        # seach for most in-a-row currently
        for endpair,score in game._lines.items():
            if score > best_score:
                best_endpair = endpair
                best_score = score
            # or block opponent one move from winning
            if -score == game.size-1 and self.smart_block:
                best_endpair = endpair
                break

        # if none found, take middle of board
        if best_endpair == None:
            middle = tuple(np.full(game.dim, game.size//2))
            if game.is_empty_here(middle):
                return middle
            return tuple(np.random.randint(0,game.size,size=game.dim))

        # search for open spot between endpoints pair
        slope = game.determine_slope(*endpair)
        search_square = np.asarray(best_endpair[0])

        while (abs(search_square) < game.size).all():
            if game.is_empty_here(tuple(search_square)):
                return tuple(search_square)
            search_square += slope

        return tuple(np.random.randint(0,game.size,size=game.dim))

