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

    def determine_slope(self, init, terminal):
        return np.asarray(
                self._determine_slope(
                    np.asarray(init, dtype=np.intc),
                    np.asarray(terminal, dtype=np.intc)
                    )
                )

    cdef int[::1] _determine_slope(self, int[::1] init, int[::1] terminal):
        cdef int[::1] slope = np.empty(self.dim,dtype=np.intc)
        for i in range(self.dim):
            if init[i] == terminal[i]:
                slope[i] = 0
            elif init[i] < terminal[i]:
                slope[i] = +1
            else: # init[i] > terminal[i]
                slope[i] = -1

        return slope

    cdef void _fill_in_endpoints(self, int[::1] init, int[::1] terminal):
        """ takes in two endpoints and traverses each cell that lays on the
            line between them, adding that endpoint tuple to the self._endpoints
            matrix/tensor, which stores a list of valid endpoints for every cell.
            self._endpoints is used too look-up/update scores (how many in a
            row sofar) when a new marker is placed in a cell. """
        cdef ssize_t i
        cdef tuple t_init = tuple(init) # used for indexing
        cdef tuple t_terminal = tuple(terminal) # used for indexing
        cdef int[::1] moving_square
        cdef tuple t_moving_square
        cdef int[::1] slope

        slope = self._determine_slope(init,terminal)
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
        cdef np.ndarray[int,ndim=1] tmp
        cdef int[::1] vec1
        cdef int[::1] vec2
        cdef list corners = self._gen_corners()
        cdef ssize_t i,j

        # covers diagonals as well as rows/columns between corners
        # so there will be some re-inits, but that doesn't matter
        for corner1 in corners:
            for corner2 in corners:
                if corner1 is corner2: continue
                self._lines[tuple(corner1),tuple(corner2)] = 0
                self._fill_in_endpoints(corner1, corner2)

        tmp = np.empty(self.dim, dtype=np.intc)
        for vec1 in self._unit_vectors:
            for vec2 in self._unit_vectors:
                if np.array_equal(vec1,vec2): continue
                init[:] = 0
                # move along one dimension at a time
                for i in range(self.size):
                    tmp[:] = init[:]
                    for j in range(self.size):
                        for opp in self._gen_opposing(init):
                            self._lines[tuple(init),tuple(opp)] = 0
                            self._fill_in_endpoints(init,opp)
                        init += vec2
                    #for j in range(self.size): init -= vec2
                    init[:] = tmp[:]
                    init += vec1

    #cdef void _update_lines(Game self, int[::1] coord):
    #    """ takes in a board position with a recently placed marker,
    #        updates self._lines with new scores (number of certain marker
    #        on a given line). """
    #    cdef int[::1] init = coord.copy()
    #    cdef int[::1] terminal = coord.copy()
    #    cdef int n = self.size-1
    #    cdef int score_change

    #    if    self.board[tuple(coord)] == xmark: score_change = xpoint
    #    elif  self.board[tuple(coord)] == omark: score_change = opoint
    #    else: raise Exception("cannot update lines with a blank square")

    #    for endpoint_pair in self._endpoint[tuple(coord)]:
    #        self._lines[endpoint_pair] += score_change

    def is_empty_here(self, tuple square):
        return self.board[square] == blank_square

    def highlight_winner(self, tuple ep1, tuple ep2):
        cdef np.ndarray[int] A = np.empty(self.dim,dtype=np.intc)
        cdef int[::1] B = np.empty(self.dim,dtype=np.intc)
        cdef int[::1] slope
        cdef ssize_t i

        for i,(a,b) in enumerate(zip(ep1,ep2)):
            A[i] = a
            B[i] = b

        slope = self._determine_slope(A,B)

        for i in range(self.size):
            self.board[tuple(A)] = '!'
            A += slope

    cdef str place_marker(self, marker_location):
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

        if self._endpoints[marker_location] == None:
            self.board[marker_location] = '*'
            return None

        for endpnt_pair in self._endpoints[marker_location]:
            if endpnt_pair not in self._lines:
                self._lines[endpnt_pair] = point
            elif point * self._lines[endpnt_pair] < 0: # heterogenous line
                self._lines[endpnt_pair] = 0
            else:
                self._lines[endpnt_pair] += point
            if abs(self._lines[endpnt_pair]) == self.size:
                self.highlight_winner(*endpnt_pair)
                return self.marker # current player wins!!!

        return None# scores updated, no winner yet

    def take_turn(self, move=None):
        """ if `move` is None, the user will be prompted to make a move """
        if self.marker == xmark:
            self.marker = omark
        else:
            self.marker = xmark

        if blank_square not in self.board:
            print("Cat's game")
            # TODO
            sys.exit() # this is bad. put something else here later

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
