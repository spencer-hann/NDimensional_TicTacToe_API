"""An agent that acts based on reinforcement learning/Q-learning."""
from collections import defaultdict

import numpy as np
from tqdm import tqdm

from .example_agents import NaiveBestFirstAgent, RandomAgent
from tictactoe import Game


class ReinforcementAgent:

    def __init__(self, marker=b'O', n=10000, m=20000, eta=0.2, g=0.9, e=1, epsilon_switch=False):
        """
        Set initial values.
        :param marker: The marker this agent will use during the game
        :param n: Number of epochs to train for
        :param m: Number of actions per training epoch
        :param eta: Learning rate
        :param g: Discount factor
        :param e: Epsilon; how likely the agent is to perform a random action
        :param opponent: Adversary to play against during training
        """
        if epsilon_switch:
            self.name = "Reinforcement Learning epsilon"
        else:
            self.name = "Reinforcement Learning"
        self.q_matrix = None
        self.marker = marker
        self._n = n
        self._m = m
        self._eta = eta
        self._g = g
        self._e_init = e
        self.epsilon_switch = epsilon_switch
        self._opponent = RandomAgent(marker=b'O' if self.marker == b'X' else b'X')
        self._trained = False

    def _update_q_matrix(self, state, square, new_state, reward):
        """Update the q_matrix using a predetermined update formula."""
        # Need to convert tuple representing indices into game board to 1D
        new = self._g * max(self.q_matrix[new_state].values())
        old = self.q_matrix[state][square]
        diff = self._eta * (reward + new - old)
        self.q_matrix[state][square] += diff

    def _act(self, game):
        """Perform a single round of actions on the game. WIP."""
        for _ in range(self._m):
            if game.game_over or game.is_full():
                break
            state = tuple(game.state())
            prev_score = game.get_score()
            square = self.next_move(game)
            winner = game.take_turn(square)
            new_state = tuple(game.state())
            if winner == self.marker:
                reward = 20
            elif winner == self._opponent.marker:
                reward = -20
            elif winner == 'C':  # Tie
                reward = 0
            else:
                # Use score differential as reward value, taking into account
                # 'O' wants a low score and 'X' wants a high score
                score_delta = game.get_score() - prev_score
                reward = -score_delta if self.marker == b'O' else score_delta
            #print(prev_score, game.get_score(), reward)
            square = np.reshape(list(self.q_matrix[state]),
                                [game.size for _ in range(game.dim)])[square]
            self._update_q_matrix(state, square, new_state, reward)
            if not (game.game_over or game.is_full()):
                game.take_turn(self._opponent.next_move(game))

    def _train(self, size, dim):
        """Train the agent on a game with the given size and dimensions."""
        if self.q_matrix is None:
            self.q_matrix = defaultdict(lambda: {
                square: 0 for square in range(pow(size, dim))
            })
        self._trained = True
        training_game = Game(size, dim)
        print(f"Training {self.name} Agent")
        for epoch in tqdm(range(1, self._n + 1)):
            training_game.new_game()
            #print(f'Training epoch {epoch}')
            self._act(training_game)
            if epoch % 50 == 0:
                self._e = max(0.1, self._e - 0.01)
        #print()

    def next_move(self, game):
        """Determine the next move to make in the game. WIP."""
        if not self._trained:
            self._e = self._e_init
            self._train(game.size, game.dim)
            self._e = 0
        if game.is_full():
            raise Exception('Reinforcement Agent trying to play on full board')
        if self.epsilon_switch and np.random.rand() < self._e: return tuple(game.random_empty_square())
        state = tuple(game.state())
        square = max(self.q_matrix[state].items(), key=lambda x: x[1])[0]
        for square, _ in sorted(self.q_matrix[state].items(),
                                key=lambda x: x[1], reverse=True):
            square = np.unravel_index(square, game.board.shape)
            if game.is_empty_here(square):
                return square
