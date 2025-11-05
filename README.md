# ABS System Effect on Minor League ⚾

The Automatic Ball-Strike challenge system will be intorduced to MLB in the 2026 season. This system represents one of the most significant changes to the strike zone in league history. Unlike the fully automated strike zone, the challenge system allows umpires to call balls and strikes as usual, but gives players and managers the ability to challenge a limited number of calls per game. When a challenge is made, the call is reviewed in real-time using Hawk-Eye tracking technology, and the call is either confirmed or overturned. To prepare for league-wide adoption, MLB has been testing both the full ABS system and the challenge-based hybrid system in the minor leagues since 2021, including at the Triple-A, Double-A, and Low-A levels. During the introduction of ABS in Spring Training 2025, MLB executive vice president of baseball operations Morgan Sword said the purpose of this challenge system was to get ball/strike calls correct in high leverage situations. 

This project aims to analyze the effects of the ABS Challenge System using pitch-by-pitch (PBP) data from minor league games over the past two seasons from Triple-A. There will be a premiliary analysis on how the ABS challenge system is being used and its effects on OBP and leverage situations.

# SetUp/Methodology ⚾

To obtain minor league play-by-play data, the **baseballr** package was used. Inside the package, I used **mlb_schedule()** to get the game_ids of the triple-a and double-a minor league games for the 2024 and 2025 seasons which was then used to obtain the pbp data of each game_ids using **mlb_pbp(**). After obtaining over 2 million observations, I had to filter games where the ABS challenge system was being utilized, filter plays where the ball/strike call was challenged which results in a dataset where the ABS challenge system was used in the play. Some features needed to be engineered like who challenged the ball/strike call (pitcher/catcher or batter) and the count they challenged on. Using this dataset, I can investigate how challanges are being used, are batters or pitchers more accurate with their challenges, which pitch location is being challenged the most, are challenges saved for certained situations like replay review etc. Furthermore, I obtained the leverage index and win probability added for each at-bat using **mlb_game_wp()** function for every game. I can further analyze if the challenge system is being used as explained by Morgan Sword. 

To estimate the causal impact of the Automated Ball-Strike (ABS) challenge system on offensive outcomes, I employed a propensity score matching approach comparing challenged at-bats from Triple-A (treatment group) to similar at-bats from Double-A (control group) where no challenge system was available. I matched on key game-state variables including leverage index, inning, score differential, outs, base runner configuration, and at-bat sequence, achieving excellent balance across all covariates with standardized mean differences below 0.025 for all variables. The final matched dataset included 16,645 challenged Triple-A at-bats paired with 16,645 comparable Double-A at-bats. I estimated the treatment effect using logistic regression models controlling for leverage, game situation, and base runner states, with robust standard errors. This quasi-experimental design allows me to isolate the effect of the challenge system by comparing nearly identical high-leverage situations across leagues that differ only in the availability of challenge technology.

The analysis is limited by the unavailability of reliable pre-ABS Triple-A data, necessitating the use of Double-A as a control group rather than the ideal within-league comparison. Pandemic disruptions in 2021 made that season's data unreliable for baseline comparison. While propensity score matching achieved excellent balance on observable game-state variables, potential residual confounding from unmeasured league-level differences remains a limitation. In addition, there were some inconsisentcy with who challenged the ball/strike calls as some challenges were made even though it would serve as a disadvantage to the challenger (i.e. challenging ball 4 as a batter).

# Preliminary Analysis ⚾

<img width="1098" height="562" alt="image" src="https://github.com/user-attachments/assets/106c28d9-fb2a-484b-a21a-01ec2f0bf192" />

Pitchers and catchers have a higher challenge success rate (52%) compared to batters (46%), suggesting they are more accurate or selective when deciding to challenge calls. Batters challenge more frequently but are less successful, indicating they may challenge more based on perception. This implies catchers and pitchers have a better idea of the strike zone (probably since they have a better view). We saw that batters challenges unsuccesfully more often than not which means the pitcher/catcher have fewer challenges to play with since challenges are lost if unsuccessful


<img width="1106" height="562" alt="image" src="https://github.com/user-attachments/assets/12cf090e-a85f-4d6b-beff-a1c5ed341f6a" />

<img width="1106" height="566" alt="image" src="https://github.com/user-attachments/assets/b023f966-3b0e-4b41-9770-97cdc60bb916" />

Challenges are overwhelmingly concentrated in two-strike counts, with the 3-2 count showing the highest volume of challenges by a significant margin. This indicates that players and teams are strategically reserving their challenges for the most high-leverage moments, specifically when a strike call would directly result in an out. But by total count, we see a high count on early counts (1-0,1-1, etc) due to most at-bats not reaching high leverage counts.

<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/abd034d5-4c1c-4d4e-9d00-858fb4006adf" />
<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/4bc525db-926a-4e24-8750-cfeee41e5362" />

Batter's challenge a high percentage of stirke 3 calls while pitchers/catchers have a more evenely distributed challneges per count with higher percentage for pitch counts where there are no strikes and a 1/2/3 balls (1-0, 2-0, 3-0 etc). The total count graph actually shows that pitchers do challenge bout the same amount as batters so the percentages are heavily influenced by the total_count of each pitch count.



<img width="1106" height="566" alt="image" src="https://github.com/user-attachments/assets/5aad832c-1ad7-4715-ae45-e6fb467cf81f" />

<img width="1094" height="568" alt="image" src="https://github.com/user-attachments/assets/72482ad2-328d-4f04-9669-5c5f81489f03" />

Higher percentage of challenges are used in the latter innings especially the 9th inning which supports the theory that challenges are being saved for higher leverage situations. Note that only half of a 9th inning is played if the home team won in regulation. 


<img width="1096" height="562" alt="image" src="https://github.com/user-attachments/assets/e7f481a9-62bc-4075-80ed-a7100a535a4b" />


<img width="1094" height="572" alt="image" src="https://github.com/user-attachments/assets/f988ee42-745c-4857-8331-308153ef41f6" />


<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/67b216f5-9b8f-464e-be0a-35a3068f18a6" />









