import dill
import pickle
import matplotlib.pyplot as plt
import numpy as np
import sys
import re

nums = re.compile(r"[0-9]+")

if len(sys.argv) < 2:
    sys.exit("Pass in file name of pickled dict.")

fnames = sys.argv[1:]

for fname in fnames:
    with open(fname, 'rb') as f:
        results = pickle.load(f)

    fname = fname[:-4] # remove ".out"

    numbers = [None] * 3
    for i,number in enumerate(re.finditer(nums,fname)):
        number = number.group()
        numbers[i] = number

    game_details = f"Size: {numbers[0]}"
    game_details += f", Dimensions: {numbers[1]}"
    if numbers[2]:
        game_details += f", RL Training Games: {numbers[2]}"

    print("creating graphs for:\n",game_details)

    for player1,opponent_dict in results.items():

        fig, axes = plt.subplots(1,len(opponent_dict), figsize=(16,4))
        fig.suptitle(f"{player1} vs.\n{game_details}'\n")

        for i,(player2,outcome_dict) in enumerate(opponent_dict.items()):
            if player2 == "Reinforcement Learning":
                player2 = "RL agent"
            if player2 == "Reinforcement Learning epsilon":
                player2 = "RL agent w/ epsilon"

            outcome_dict = sorted(outcome_dict.items(), reverse=True)

            axes[i].set_ylim(top=100)
            axes[i].set_title(f"{player2}")
            axes[i].bar(
                        [key for key,_ in outcome_dict],
                        [count for _,count in outcome_dict]
                    )
        plt.subplots_adjust(top=0.75)
        plt.savefig("./images/" + fname + '_' + player1 + ".png")
        for ax in axes:
            ax.clear()
