# simple example agents for tictactoe.pyx
# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

import numpy as np

class RandomAgent:
    def __init__(self, marker='X'):
        self.name = "Random"
        self.marker = marker

    def next_move(self, game):
        if game.is_full():
            raise Exception("Random Agent trying to play on full board")
        return tuple(game.random_empty_square())
        #while 1:
        #for i in range(100): # eventually just give up
        #    coord = tuple(np.random.randint(0,game.size,size=game.dim))
        #    if game.is_empty_here(coord):
        #        break
        #return coord

# NaiveBestFirstAgent is incomplete.
# currently only able to play as 'X'
class NaiveBestFirstAgent:
    def __init__(self, marker, smart_block=False):
        self.name = "Naive Best First"
        self.marker = marker
        self.smart_block = smart_block

    def next_move(self, game):
        best_endpair = None
        best_score = 0
        score_lock = False

        # seach for most in-a-row currently
        for endpair,score in game._lines.items():
            # only adjust if not about to lose else where (smart_block)
            if score > best_score and not score_lock:
                best_endpair = endpair
                best_score = score
            if score == game.size-1: # about to win, forget smart_block
                best_endpair = endpair
                break
            # or block opponent one move from winning
            if -score == game.size-1 and self.smart_block:
                best_endpair = endpair
                score_lock = True

        # if none found, take middle of board
        if best_endpair == None:
            middle = tuple(np.full(game.dim, game.size//2))
            if game.is_empty_here(middle):
                return middle
            # if middle is take choose at random
            return tuple(game.random_empty_square())

        # search for open spot between endpoints pair
        slope = game.determine_slope(*best_endpair)
        search_square = np.asarray(best_endpair[0])

        while (abs(search_square) < game.size).all():
        #while (search_square < game.size).all() and (search_square >= 0).all():
            if game.is_empty_here(tuple(search_square)):
                return tuple(search_square)
            search_square += slope

        return tuple(game.random_empty_square())
