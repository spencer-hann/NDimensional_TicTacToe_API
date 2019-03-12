# n-dimensional tictactoe API for testing/training
# intelligent agents

# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

# cython: language_level=3

import numpy as np
cimport numpy as np
import pandas as pd
import sys

DEF blank_square = b'_'

DEF xmark = b'X'
DEF omark = b'O'

DEF xpoint = +1
DEF opoint = -1

DEF xwinmark = b'+'
DEF owinmark = b'0'

cdef class Game:
    cdef readonly np.ndarray board
    #cdef set _seeds
    #cdef int[::1] _init_seed
    cdef readonly int size
    cdef readonly int dim
    cdef readonly bytes marker
    cdef set _unit_vectors
    cdef readonly dict _lines
    cdef readonly bint game_over
    cdef np.ndarray _endpoints

    # default to 3x3 board, 'X' goes first
    def __cinit__(Game self, int size=3, int dim=2):
        self.marker = xmark
        self.game_over = False

        self.board = np.empty([size]*dim,dtype=bytes)
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

    @staticmethod
    def determine_point_value(bytes marker):
        """ returns the point value added to a line when the a
            marker of the type passed in is placed on that line.
            This is useful for determining if an agent is trying to
            minimize or maximize line scores """
        if marker == xmark:
            return xpoint
        return opoint

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
                # move along one dimension at a t  ime
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

    def is_empty_here(self, tuple square):
        r"""returns True, if legal move
            returns False, if square is already occupied
            throws exceptions for bad indices """
        return self.board[square] == blank_square

    cdef void highlight_winner(self, tuple ep1, tuple ep2):
        r"""Takes the endpoint pair for the winning line at the end of
            the game.
            Changes all markers on board to lowercase, except for those,
            on the winning line, between `ep1` and `ep2`"""
        cdef np.ndarray[int] A = np.empty(self.dim,dtype=np.intc)
        cdef int[::1] B = np.empty(self.dim,dtype=np.intc)
        cdef int[::1] slope
        cdef ssize_t i

        if not self.game_over:
            raise Exception("In `Game.highlight_winner`: Game is not yet over.")

        # convert tuples back to np.ndarrays
        for i,(a,b) in enumerate(zip(ep1,ep2)):
            A[i] = a
            B[i] = b

        slope = self._determine_slope(A,B)

        self.board = np.char.lower(self.board)
        #self.board = np.char.lower(self.board.astype(unicode))

        for i in range(self.size):
            #self.board[tuple(A)] = marker
            self.board[tuple(A)] = self.board[tuple(A)].upper()
            A += slope

    cdef str _place_marker(self, tuple marker_location):
        r"""this function is used in the `Game.take_turn` function, and
            should not be called directly"""
        cdef int point
        cdef list lines

        if self.board[marker_location] != blank_square:
            return None

        if self.marker == xmark:
            point = xpoint
        else:
            point = opoint

        self.board[marker_location] = self.marker

        # for debugging _endpoints
        if self._endpoints[marker_location] == None:
            self.board[marker_location] = b'*'
            return None

        for endpnt_pair in self._endpoints[marker_location]:
            if endpnt_pair not in self._lines:
                self._lines[endpnt_pair] = point
            elif point * self._lines[endpnt_pair] < 0: # heterogenous line
                self._lines[endpnt_pair] = float("nan") # dead line
            else:
                self._lines[endpnt_pair] += point
            if abs(self._lines[endpnt_pair]) == self.size:
                self.game_over = True
                self.highlight_winner(endpnt_pair[0],endpnt_pair[1])
                return self.marker.decode("utf-8") # current player wins!!!

        if blank_square not in self.board:
            return 'C' # for Cat's game

        return None# scores updated, no winner yet

    def take_turn(self, move=None):
        r"""Args:
                move: Iterable (is optional)

            return type:
                str or None
                may return int or throw exception for errors

            `move` sould be an Iterable containing the int coordinates at
            which to place the marker. Default value is `None`.

            If `move` is None, the user will be prompted to make a move.
            AI players should always specify a move.

            If the move was a winning move, the winning player's marker is
            returned as a Python str.

            If the move was a legal, non-winning moves, `None` will be returned.

            If the board is full, a capital 'C' will be returned,
            representing a cat's game.

            If the board location is already occupied by another marker, the
            marker will not be placed, and `None` will be returned.
            Agents should use the `Game.is_empty_here` function to validate
            potential moves before making them.

            Bad coordinates are not handled, so this will result in numpy
            throwing some bad index exception."""
        if self.marker == xmark:
            self.marker = omark
        else:
            self.marker = xmark

        move = tuple(move)

        if self.board[move] != blank_square:
            return -1

        return self._place_marker(move)

    def display_board(self, turn_number=False):
        r""" prints board to console, if desired `turn_number` will be
            displayed about the board """
        if self.dim > 3: return # don't want to display in 4+ dimensions...

        cdef np.ndarray str_board = self.board.astype(unicode)

        if turn_number is not False:
            print('-'*20,"Turn",turn_number,'-'*20)

        if self.dim < 3:
            print(pd.DataFrame(str_board))
            return

        for i in range(self.size):
            print("\nLayer",i)
            print(pd.DataFrame(str_board[i]))

    cpdef np.ndarray state(self):
        r"""returns a flattened copy of the game board as an np.ndarray"""
        return self.board.flatten()

    cpdef bytes state_hash(self):
        r"""returns a flattened copy of the game board converted
            into a `bytes` object for hashing """
        return bytes(self.board.flatten())

    def new_game(self):
        r""" when a game is over, this will quickly clear the board
            and reset other aspect of the game object's internal state.
            This is better than re-building the game from scratch,
            which may take a non-trivial amount of time for large
            boards in higher dimensions """
        self.board.fill(blank_square)

        self.marker = xmark

        for key in self._lines:
            self._lines[key] = 0

        self.game_over = False

    def is_full(self):
        return blank_square not in self.board

    #def is_unwinnable(self): pass

    def random_empty_square(self):
        r"""returns the location of random empty square as a
            numpy array. If the board is full (no empty squares)
            an Exception is thrown"""
        cdef:
            np.ndarray coord = np.zeros(self.dim, dtype=np.intc)
            char[::1] flat = self.board.flatten()
            int i = np.random.randint(0,flat.shape[0])
            int i_init = i
            int i_dim = self.dim - 1
            int coord_dim = 0
            int chunk = self.size ** i_dim

        while 1:
            i += 1
            if i == flat.shape[0]: # start from beginning
                i = 0
            if flat[i] == blank_square: # done
                break
            if i == i_init: # made full loop with no blank squares
                raise Exception("In `Game.random_empty_square`: game board is full")

        while coord_dim < self.dim:
            coord[coord_dim] = i // chunk
            i %= chunk
            coord_dim += 1
            i_dim -= 1
            chunk = self.size ** i_dim

        return coord

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



######################################################
# HumanPlayer:                                       #
#   Bonus class for users to play against each other #
#   or against AIs                                   #
######################################################

global HumanPlayer_count
HumanPlayer_count = 0

class HumanPlayer:
    def __init__(self,name=None):
        global HumanPlayer_count
        if name is None:
            HumanPlayer_count += 1
            self.name = f"Human Player {HumanPlayer_count}"
        else:
            self.name = name

    # HumanPlayer.next_move does not need the game object
    # However, the next_move function of other player objects might
    # including the `game` parament allows HumanPlayer objects to
    # interact with the game similarly to other player objects
    def next_move(self,game=None):
        print(f"{self.name}, make your move...")
        move = input().strip()

        if move[0] == '(': move = move[1:]
        if move[-1] == ')': move = move[:-1]
        if ',' in move: move = move.split(',')
        else: move = move.split(' ')

        return tuple(map(int,move))
