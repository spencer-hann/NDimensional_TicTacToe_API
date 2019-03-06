# n-dimensional tic-tac-toe
# author: Spencer Hann - github.com/spencer-hann

# cython: language_level=3

import numpy as np
cimport numpy as np
import pandas as pd
import sys

DEF blank_square = '_'

DEF xmark = 'X'
DEF omark = 'O'

DEF xpoint = +1
DEF opoint = -1

DEF xmarkwin = '+'
DEF omarkwin = '0'

cdef class Game:
    cdef readonly np.ndarray board
    #cdef set _seeds
    #cdef int[::1] _init_seed
    cdef readonly int size
    cdef readonly int dim
    cdef readonly str marker
    cdef set _unit_vectors
    cdef readonly dict _lines
    cdef np.ndarray _endpoints

    # class var for access outside the module
    empty_square = blank_square

    # default to 3x3 board, 'X' goes first
    def __cinit__(Game self, int size=3, int dim=2):
        self.marker = xmark

        self.board = np.empty([size]*dim,dtype=str)
        self.board.fill(blank_square)
        self.size = size
        self.dim = dim

        self._endpoints = np.empty([size]*dim,dtype=set)

        #self._seeds = set()
        #self._init_seed = np.zeros(dim, dtype=np.intc)
        #self._gen_seeds(self._init_seed, 0)
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
        cdef int[::1] vec = np.zeros(self.dim, dtype=np.intc)

        for i in range(self.dim):
            vec[i] = 1
            self._unit_vectors.add(vec.copy())
            vec[i] = 0

    cdef list _gen_corners(self):
        """ returns locations of all corners as a set of int memoryviews.
            a corner is any coodinate where all values are either
            0 or n. This function basically counts up in binary
            (except with n's instead of 1's), adding every possible
            corner for the board/tensor shape to the 'corners' set.
            Ex. (0,0,0), (0,0,n), (0,n,0), (0,n,n), ... """
        cdef int[::1] corner = np.zeros(self.dim, dtype=np.intc)
        cdef list corners = [corner]
        cdef int place, n = self.size-1

        while True:
            place = 0
            while place < self.dim and corner[place] == n:
                corner[place] = 0
                place += 1

            if place == self.dim: break

            corner[place] = n
            corners.append(corner.copy())

        return corners

    cdef set _gen_opposing(self, int[::1] coord):
        """ takes a scaled unit vector as input, returns all opposing
            cells in board/tensor that represent the other end of a
            winning line. Similar to _gen_corners, it uses a binary
            counting approach, but skips over dimensions where 'coord'
            is not on the perimiter.
            returns set of tuples """
        cdef set opposing = set()
        cdef int place, n = self.size-1

        coord = coord.copy() # prevent side effects

        while True:
            place = 0
            while place < self.dim and coord[place] != 0:
                if coord[place] == n: coord[place] = 0
                place += 1

            if place == self.dim: break

            if coord[place] == 0: coord[place] = n
            opposing.add(coord.copy())

        return opposing

    cdef void _fill_in_endpoints(self, int[::1] init, int[::1] terminal):
        """ takes in two endpoints and traverses each cell that lays on the
            line between them, adding that endpoint tuple to the self._endpoints
            matrix/tensor, which stores a list of valid endpoints for every cell.
            self._endpoints is used too look-up/update scores (how many in a
            row sofar) when a new marker is placed in a cell. """
        cdef int[::1] slope = np.empty(init.shape[0],dtype=np.intc)
        cdef ssize_t i
        cdef tuple t_init = tuple(init) # used for indexing
        cdef tuple t_terminal = tuple(terminal) # used for indexing
        cdef int[::1] moving_square
        cdef tuple t_moving_square

        for i in range(init.shape[0]):
            if init[i] == terminal[i]:
                slope[i] = 0
            elif init[i] < terminal[i]:
                slope[i] = +1
            else: # init[i] > terminal[i]
                slope[i] = -1

        moving_square = init.copy()

        while not np.array_equal(moving_square,terminal):
            t_moving_square = tuple(moving_square)

            if not self._endpoints[t_moving_square]:
                self._endpoints[t_moving_square] = set()

            self._endpoints[t_moving_square].add((t_init, t_terminal))
            self._endpoints[t_moving_square].add((t_terminal, t_init))

            for i in range(slope.shape[0]):
                moving_square[i] += slope[i]

        if not self._endpoints[t_terminal]:
            self._endpoints[t_terminal] = {(t_init, t_terminal)}
        else:
            self._endpoints[t_terminal].add((t_init, t_terminal))

    cdef void _init_lines(self):
        """ adds all keys to the self._lines dict and inits all values to 0.
            all keys are pairs of coordinates that lie around the edges of the
            game board/tensor at either end of a "winning line", for example,
            ((0,1),(2,1)) on a 3x3 board, or any pair of corners. self._lines
            will be used as a counter for number of markers in that row/
            column/diagonal """
        cdef np.ndarray[int,ndim=1] init = np.zeros(self.dim, dtype=np.intc)
        cdef np.ndarray[int,ndim=1] terminal = np.empty(self.dim, dtype=np.intc)
        cdef list corners = self._gen_corners()
        cdef ssize_t i,j

        # covers diagonals as well as rows/columns between corners
        # so there will be some re-inits, but that doesn't matter
        for corner1 in corners:
            for corner2 in corners:
                if corner1 is corner2: continue
                self._lines[tuple(corner1),tuple(corner2)] = 0
                self._fill_in_endpoints(corner1, corner2)

        # all rows and columns
        for vec in self._unit_vectors:
            init[:] = 0
            # move along one dimension at a time
            for i in range(self.size-1):
                init += vec
                for opp in self._gen_opposing(init):
                    self._lines[tuple(init),tuple(opp)] = 0
                    self._fill_in_endpoints(init,opp)

    cdef void _update_lines(Game self, int[::1] coord):
        """ takes in a board position with a recently placed marker,
            updates self._lines with new scores (number of certain marker
            on a given line). """
        cdef int[::1] init = coord.copy()
        cdef int[::1] terminal = coord.copy()
        cdef int n = self.size-1
        cdef int score_change

        if    self.board[tuple(coord)] == xmark: score_change = +1
        elif  self.board[tuple(coord)] == omark: score_change = -1
        else: raise Exception("cannot update lines with a blank square")

        for endpoint_pair in self._endpoint[tuple(coord)]:
            self._lines[endpoint_pair] += 1

        # determine the non-diagonal lines
        # that 'coord' belongs to
#        for i in range(coord.shape[0]):
#            init[i] = 0
#            terminal[i] = n
#
#            self._lines[tuple(init),tuple(terminal)] += score_change
#
#            init[i] = coord[i]
#            terminal[i] = coord[i]
#
    cpdef str place_marker(self, marker_location):
        cdef int point
        cdef list lines

        marker_location = tuple(marker_location)
        if self.board[marker_location] != blank_square:
            return False

        if self.marker == xmark:
            point = xpoint
        else:
            point = opoint

        self.board[marker_location] = self.marker

        for endpnt_pair in self._endpoints[marker_location]:
            if endpnt_pair not in self._lines:
                self._lines[endpnt_pair] = 0
            #print(endpnt_pair,self._lines[endpnt_pair],point)
            self._lines[endpnt_pair] += point
            #print(endpnt_pair,self._lines[endpnt_pair])
            if abs(self._lines[endpnt_pair]) == self.size:
                return self.marker # current player wins!!!

        return None# scores updated, no winner yet

    def take_turn(self, move=None):
        """ if `move` is None, the user will be prompted to make a move """
        if self.marker == xmark:
            self.marker = omark
        else:
            self.marker = xmark

        if move == None:
            print(f"Player {self.marker}, make your move...")
            move = input().strip()

            if move[0] == '(': move = move[1:]
            if move[-1] == ')': move = move[:-1]
            if ',' in move: move = move.split(',')
            else: move = move.split(' ')

            move = tuple(map(int,move))

        return self.place_marker(move)

    def display_board(self):
        if self.dim < 3:
            print(pd.DataFrame(self.board))
            return

        if self.dim > 3: return # don't want to display in 4 dimensions...

        for i in range(self.size):
            print("\nLayer",i)
            print(pd.DataFrame(self.board[i]))

    cpdef tuple state_hash(self):
        return tuple(self.board.flatten())




#    cdef _gen_seeds(self, int[::1] seed, int dim):
#        if dim == self.dim: return
#
#        self._gen_seeds(seed, dim+1)
#
#        new_seed = seed.copy()
#        new_seed[dim] = +1
#        self.seeds.add(new_seed)
#        self._gen_seeds(new_seed, dim+1)
#
#        new_seed = seed.copy()
#        new_seed[dim] = -1
#        self.seeds.add(new_seed)
#        self._gen_seeds(new_seed, dim+1)
