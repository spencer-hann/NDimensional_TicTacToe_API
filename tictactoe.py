# github.com/spencer-hann/NDimensional_TicTacToe_API
# Author: Spencer Hann

import dill
import pickle
from tictactoe import Game, HumanPlayer
from agents import NaiveBestFirstAgent, RandomAgent, ReinforcementAgent, RuleBasedAgent
from collections import defaultdict, Counter
from tqdm import tqdm


def play_game(
        game,
        players=(HumanPlayer(), NaiveBestFirstAgent(b'X')),
        display=True):
    assert len(players) == 2, 'Only two players'

    if display: game.display_board()

    turn = 0
    while 1:
        for player in players:
            turn += 1
            if display: print(f' Turn {turn}'.center(28, '-'))

            winner = game.take_turn(player.next_move(game))
            if display: game.display_board()

            if winner == 'C':
                if display: print("Cat's game...")
                return winner
            elif winner:
                if display: print(winner, 'is the winner!!!')
                return winner

if __name__ == '__main__':
    print('Building game...', end=' ', flush=True)
    game = Game(size=4, dim=3)
    print(game.size, game.dim)
    print('done!')

    play_game(game, players=(HumanPlayer(),RuleBasedAgent(b'X', skill_level=2)))

    #winners = []

    #all_players_O = [
    #            RandomAgent(b'O'),
    #            NaiveBestFirstAgent(b'O'),
    #            RuleBasedAgent(b'0', skill_level=1),
    #            RuleBasedAgent(b'0', skill_level=2),
    #            RuleBasedAgent(b'0', skill_level=3),
    #            ReinforcementAgent(b'O', epsilon_switch=False),
    #            ReinforcementAgent(b'O', epsilon_switch=True)
    #        ]

    #all_players_X = [
    #            RandomAgent(b'X'),
    #            NaiveBestFirstAgent(b'X'),
    #            RuleBasedAgent(b'X', skill_level=1),
    #            RuleBasedAgent(b'X', skill_level=2),
    #            RuleBasedAgent(b'X', skill_level=3),
    #            ReinforcementAgent(b'X', epsilon_switch=False),
    #            ReinforcementAgent(b'X', epsilon_switch=True)
    #        ]

    ## check if game is too large for rl agents
    #if game.size > 4 or game.dim > 4:
    #    all_players_O = all_players_O[:-2]
    #    all_players_X = all_players_X[:-2]
    #    rl_agents = []
    #else:
    #    rl_agents = [all_players_O[-1], all_players_O[-2],
    #                 all_players_X[-1], all_players_X[-2]]

    #winners = defaultdict(lambda:defaultdict(lambda:{"win":0,"lose":0,"draw":0}))

    #def outcome_for(marker, winner):
    #    if winner == marker:
    #        return "win"
    #    if winner == 'C':
    #        return "draw"
    #    return "lose"

    #for i, O_player in enumerate(all_players_O):
    #    print(f"Trial {i+1} of {len(all_players_O)}")

    #    if rl_agents: Xiter = all_players_X
    #    else: Xiter = tqdm(all_players_X)

    #    for X_player in Xiter:
    #        for i in range(50):
    #            winner = play_game(game, players=[O_player, X_player], display=False)
    #            #print(O_player.name, X_player.name, winner)

    #            outcome = outcome_for('O', winner)
    #            winners[O_player.name][X_player.name][outcome] += 1

    #            outcome = outcome_for('X', winner)
    #            winners[X_player.name][O_player.name][outcome] += 1

    #            game.new_game()
    #        for rl in rl_agents: rl._trained = False
    #    for rl in rl_agents: rl._trained = False
    #    print() # new line

    #winners = dict(winners) # convert to plain dict (no lambdas) for pickling
    #for p1 in winners.keys():
    #    winners[p1] = dict(winners[p1]) # convert to plain dict for pickling
    #    print(f"{p1} matches vs.")
    #    for p2 in winners[p1]:
    #        print(f"    {p2}\t->", end='\t')
    #        for result_type,result in winners[p1][p2].items():
    #            print(f"{result_type}:{result},", end=' ')
    #        print()
    #    print()

    #if rl_agents:
    #    fname = f"results_size{game.size}_dim{game.dim}_rlepochs{rl_agents[0]._n}.out"
    #else:
    #    fname = f"results_size{game.size}_dim{game.dim}.out"

    #with open(fname, 'wb') as f:
    #    pickle.dump(winners,f)
