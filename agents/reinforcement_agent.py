"""An agent that acts based on reinforcement learning/Q-learning."""
from collections import defaultdict

import numpy as np

from .example_agents import NaiveBestFirstAgent, RandomAgent
from tictactoe import Game


class ReinforcementAgent:

    def __init__(self, marker='X', n=1000, m=200, eta=0.2, g=0.9, e=1):
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
        self.name = "Reinforcement Learning"
        self.marker = marker
        self.n = n
        self.m = m
        self.eta = eta
        self.g = g
        self.e = e
        self.opponent = RandomAgent(marker='O' if self.marker == 'X' else 'X')
        self.trained = False

    def _update_q_matrix(self, state, square, new_state, reward):
        """Update the q_matrix using a predetermined update formula."""
        # Need to convert tuple representing indices into game board to 1D
        new = self.g * max(self.q_matrix[new_state].values())
        old = self.q_matrix[state][square]
        diff = self.eta * (reward + new - old)
        self.q_matrix[state][square] += diff

    def _act(self, game):
        """Perform a single round of actions on the game. WIP."""
        for _ in range(self.m):
            if game.game_over or game.is_full():
                print('Over')
                break
            state = tuple(game.state())
            square = self.next_move(game)
            winner = game.take_turn(square)
            new_state = tuple(game.state())
            if winner == -1:  # Attempted to place on non-blank square
                reward = -5
            elif winner == self.marker:
                reward = 20
            elif winner == self.opponent.marker:
                reward = -20
            else:
                reward = 20
            square = np.reshape(list(self.q_matrix[state]),
                                [game.size for _ in range(game.dim)])[square]
            self._update_q_matrix(state, square, new_state, reward)
            if not (game.game_over or game.is_full()):
                game.take_turn(self.opponent.next_move(game))

    def _train(self, size, dim):
        """Train the agent on a game with the given size and dimensions."""
        self.q_matrix = defaultdict(lambda: {
            square: 0 for square in range(pow(size, dim))
        })
        self.trained = True
        training_game = Game(size, dim)
        for epoch in range(1, self.n + 1):
            training_game.new_game()
            print(f'Training epoch {epoch}', end='\r')
            self._act(training_game)
            if epoch % 50 == 0:
                self.e = max(0.1, self.e - 0.01)
        print()

    def next_move(self, game):
        """Determine the next move to make in the game. WIP."""
        if not self.trained:
            self._train(game.size, game.dim)
        state = tuple(game.state())
        square = max(self.q_matrix[state].items(), key=lambda x: [1])[0]
        return np.unravel_index(square, game.board.shape)
