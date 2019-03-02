import time
from IPython.display import display, clear_output
import numpy as np
import pandas as pd

DEF xmark = 'X'
DEF omark = 'O'
DEF blank_square = '_'

cdef class Game:
    cdef np.ndarray board
    cdef set _seeds
    cdef int[::1] _init_seed

    def __cinit__(self, size=3, dim=2): # default to normal 3x2 board
        self.board = np.empty([size]*dim,dtype=str)
        self.board.fill(blank_square)
        self.size = size
        self.dim = dim

        self._seeds = set()
        self._init_seed = np.zeros(dim, dtype=np.intc)
        self._gen_seeds(self._init_seed, 0)
        self._unit_vectors = set()
        self._gen_unit_vectors()

        # a "line" is a n-in-a-row streak to win the game:
        # in the traditional game, 3x3, getting 3-in-a-row wins
        self._lines = {}
        self._init_lines()

    cdef void _gen_unit_vectors(self):
        """ creates all unit vectors in self.dim-dimensional space.
            stores results in self._unit_vectors. Unit vectors are used
            to traverse parimeters in _init_lines() """
        cdef int i
        cdef int[::1] vec = np.zeros(dim, dtype=np.intc)

        for i in range(dim):
            vec[i] = 1
            self._unit_vectors.add(vec.copy)
            vec[i] = 0

    cdef set _gen_corners(self):
        """ returns locations of all corners as a set of int memoryviews.
            a corner is any coodinate where all values are either
            0 or n. This function basically counts up in binary
            (except with n's instead of 1's), adding every possible
            corner for the board/tensor shape to the 'corners' set """
        cdef int[::1] corner = np.zeros(self.dim, dtype=np.intc)
        cdef set corners = {corner}
        cdef int place, n = self.size-1

        while True:
            place = 0
            while corner[place] == n and place < self.dim:
                corner[place] = 0
                place += 1

            if place == self.dim: break

            corner[place] = n
            corners.add(corner.copy())

        return corners

    cdef set _gen_opposing_pairs(self, int[::1] coord):
        """ takes a scaled unit vector as input, returns all opposing
            cells in board/tensor that represent the other end of a
            winning line, not including diagonals. Similar to _gen_corners,
            it uses a binary counting approach, but skips over dimensions
            where 'coord' is somewhere in the middle.
            returns set of tuples """
        cdef set opposing = set()
        cdef int place, n = self.size-1

        while True:
            place = 0
            while coord[place] != 0 and place < self.dim:
                if coord[place] == n: coord[place] = 0
                place += 1

            if place == self.dim: break

            if coord[place] == 0: coord[place] = n
            opposing.add(*coord)

        return opposing

    cdef void _init_lines(self):
        """ adds all keys to the self._lines dict and inits all values to 0.
            all keys are pairs of coordinates that lie around the edges of the
            game board/tensor at either end of a "winning line", for example,
            ((0,1),(2,1)) on a 3x3 board, or any pair fo corners. self._lines
            will be used as a counter for number of markers in that row/
            column/diagonal """
        cdef int[::1] init = np.zeros(dim, dtype=np.intc)
        cdef int[::1] terminal = np.empty(dim, dtype=np.intc)
        cdef set corners = self.gen_corners()

        # covers diagonals as well as rows/columns between corners
        # so there will be some re-inits, but that doesn't matter
        for corner1 in corners:
            for corner2 in corners:
                if corner1 is corner2: continue
                self._lines[*corner1,*corner2] = 0

        # all rows and columns
        for vec in self._unit_vectors:
            init[:] = 0
            # move along one dimension at a time
            while i < size-1:
                init += vec
                for o in self._gen_opposing(init):
                    self._lines[*init,o] = 0

    cdef void _update_lines(Game self, int[::1] coord):
        """ takes in a board position with a newly placed marker,
            updates self._lines with new scores (number of certain marker
            on a given line). """
        cdef int[::1] init = coord.copy()
        cdef int[::1] terminal = coord.copy()
        cdef int n = self.size-1
        cdef int score_change

        if self.board[tuple(coord)] == xmark:
            score_change = +1
        elif self.board[tuple(coord)] == omark:
            score_change = -1
        else:
            raise Exception("cannot update lines with a blank square")

        # determine the non-diagonal lines
        # that 'coord' belongs to
        for i in range(tmp.shape[0]):
            init[i] = 0
            terminal[i] = n

            self._lines[tuple(init),tuple(terminal)] += score_change

            init[i] = coord[i]
            terminal[i] = coord[i]


    cdef _gen_seeds(self, int[::1] seed, int dim):
        if dim == self.dim: return

        self._gen_seeds(seed, dim+1)

        new_seed = seed.copy()
        new_seed[dim] = +1
        self.seeds.add(new_seed)
        self._gen_seeds(new_seed, dim+1)

        new_seed = seed.copy()
        new_seed[dim] = -1
        self.seeds.add(new_seed)
        self._gen_seeds(new_seed, dim+1)
