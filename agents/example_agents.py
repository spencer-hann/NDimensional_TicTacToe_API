# simple example agents for tictactoe.pyx
# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

import numpy as np
from tictactoe import Agent

class RandomAgent(Agent):
    def __init__(self, marker, name="Random"):
        super().__init__(marker, name)

    def next_move(self, game):
        if game.is_full():
            raise Exception("Random Agent trying to play on full board")
        return tuple(game.random_empty_square())

class NaiveBestFirstAgent(Agent):
    def __init__(self, marker, name="Naive Best First"):
        super().__init__(marker, name)

    def next_move(self, game):
        best_endpair = None
        best_score = 0
        point_value = game.determine_point_value(self.marker)

        # seach for most in-a-row currently
        for endpair,score in game._lines.items():
            score *= point_value
            # only adjust if not about to lose else where (smart_block)
            if score > best_score:
                best_endpair = endpair
                best_score = score

        # if none found, take middle of board
        if best_endpair == None:
            middle = tuple(np.full(game.dim, game.size//2))
            if game.is_empty_here(middle):
                return middle
            # if middle is taken choose at random
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

class RuleBasedAgent(Agent):
    def __init__(self, marker, name=None, skill_level=3):
        self.skill_level = skill_level

        if name == None:
            name = f"Rule-Based level{skill_level}"
        super().__init__(marker, name)

    def next_move(self, game):
        best_endpair = None
        best_score = 0
        score_lock = False
        point_value = game.determine_point_value(self.marker)

        # seach for most in-a-row currently
        for endpair,score in game._lines.items():
            score *= point_value
            # only adjust if not about to lose else where (smart_block)
            if score > best_score and not score_lock:
                best_endpair = endpair
                best_score = score
            if score == game.size-1: # about to win, forget smart_block
                best_endpair = endpair
                break
            # or block opponent one move from winning
            if self.skill_level >= 2 and -score == game.size-1:
                best_endpair = endpair
                score_lock = True
            # stop opponent from creating trap
            if self.skill_level >= 3 and -score == game.size-2 and not score_lock:
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
