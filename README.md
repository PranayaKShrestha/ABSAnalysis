# ABS System Effect on Minor League ⚾

The Automatic Ball-Strike challenge system will be intorduced to MLB in the 2026 season. This system represents one of the most significant changes to the strike zone in league history. Unlike the fully automated strike zone, the challenge system allows umpires to call balls and strikes as usual, but gives players and managers the ability to challenge a limited number of calls per game. When a challenge is made, the call is reviewed in real-time using Hawk-Eye tracking technology, and the call is either confirmed or overturned. To prepare for league-wide adoption, MLB has been testing both the full ABS system and the challenge-based hybrid system in the minor leagues since 2021, including at the Triple-A, Double-A, and Low-A levels. During the introduction of ABS in Spring Training 2025, MLB executive vice president of baseball operations Morgan Sword said the purpose of this challenge system was to get ball/strike calls correct in high leverage situations. 

This project aims to analyze the effects of the ABS Challenge System using pitch-by-pitch (PBP) data from minor league games over the past two seasons from Triple-A. There will be a premiliary analysis on how the ABS challenge system is being used and its effects on OBP and win probability changes.

# SetUp/Methodology ⚾

To obtain minor league play-by-play data, the **baseballr** package was used. Inside the package, I used **mlb_schedule()** to get the game_ids of the triple-a and double-a minor league games for the 2024 and 2025 seasons which was then used to obtain the pbp data of each game_ids using **mlb_pbp(**). After obtaining over 2 million observations, I had to filter games where the ABS challenge system was being utilized, filter plays where the ball/strike call was challenged which results in a dataset where the ABS challenge system was used in the play. Some features needed to be engineered like who challenged the ball/strike call (pitcher/catcher or batter) and the count they challenged on. Using this dataset, I can investigate how challanges are being used, are batters or pitchers more accurate with their challenges, which pitch location is being challenged the most, are challenges saved for certained situations like replay review etc. Furthermore, I obtained the leverage index and win probability added for each at-bat using **mlb_game_wp()** function for every game. I can further analyze if the challenge system is being used as explained by Morgan Sword. 

To estimate the causal impact of the Automated Ball-Strike (ABS) challenge system on offensive outcomes, I employed a propensity score matching approach comparing challenged at-bats from Triple-A (treatment group) to similar at-bats from Double-A (control group) where no challenge system was available. I matched on key game-state variables including leverage index, inning, score differential, outs, base runner configuration, and at-bat sequence, achieving excellent balance across all covariates with standardized mean differences below 0.025 for all variables. The final matched dataset included 16,645 challenged Triple-A at-bats paired with 16,645 comparable Double-A at-bats. I estimated the treatment effect using logistic regression models controlling for leverage, game situation, and base runner states, with robust standard errors. This quasi-experimental design allows me to isolate the effect of the challenge system by comparing nearly identical high-leverage situations across leagues that differ only in the availability of challenge technology.

The analysis is limited by the unavailability of reliable pre-ABS Triple-A data, necessitating the use of Double-A as a control group rather than the ideal within-league comparison. Pandemic disruptions in 2021 made that season's data unreliable for baseline comparison. While propensity score matching achieved excellent balance on observable game-state variables, potential residual confounding from unmeasured league-level differences remains a limitation. In addition, there were some inconsisentcy with who challenged the ball/strike calls as some challenges were made even though it would serve as a disadvantage to the challenger (i.e. challenging ball 4 as a batter).

# Analysis ⚾

<img width="1098" height="562" alt="image" src="https://github.com/user-attachments/assets/106c28d9-fb2a-484b-a21a-01ec2f0bf192" />

Pitchers and catchers have a higher challenge success rate (52%) compared to batters (46%), suggesting they are more accurate or selective when deciding to challenge calls. Batters challenge more frequently but are less successful, indicating they may challenge more based on perception. This implies catchers and pitchers have a better idea of the strike zone (probably since they have a better view). We saw that batters challenges unsuccesfully more often than not which means the pitcher/catcher have fewer challenges to play with since challenges are lost if unsuccessful


## Challenges by Pitch Count 
<img width="1106" height="562" alt="image" src="https://github.com/user-attachments/assets/12cf090e-a85f-4d6b-beff-a1c5ed341f6a" />

<img width="1106" height="566" alt="image" src="https://github.com/user-attachments/assets/b023f966-3b0e-4b41-9770-97cdc60bb916" />

Challenges are overwhelmingly concentrated in two-strike counts, with the 3-2 count showing the highest volume of challenges by a significant margin. This indicates that players and teams are strategically reserving their challenges for the most high-leverage moments, specifically when a strike call would directly result in an out. But by total count, we see a high count on early counts (1-0,1-1, etc) due to most at-bats not reaching high leverage counts.

## Challenges by Pitch Count and by Challenger

<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/abd034d5-4c1c-4d4e-9d00-858fb4006adf" />
<img width="1104" height="566" alt="image" src="https://github.com/user-attachments/assets/58804740-d8e8-4cb4-81ea-6662357a8189" />

Batter's challenge a high percentage of stirke 3 calls while pitchers/catchers have a more evenely distributed challneges per count with higher percentage for pitch counts where there are no strikes and a 1/2/3 balls (1-0, 2-0, 3-0 etc). The total count graph actually shows that pitchers do challenge bout the same amount as batters so the percentages are heavily influenced by the total_count of each pitch count.

## Challenges by Inning

<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/4bc525db-926a-4e24-8750-cfeee41e5362" />
<img width="1106" height="566" alt="image" src="https://github.com/user-attachments/assets/5aad832c-1ad7-4715-ae45-e6fb467cf81f" />

 challenge usage increases significantly as the game progresses, with the highest volume and percentage of challenges occurring in the final innings (7th, 8th, and 9th). This pattern indicates that teams are strategically conserving their challenges for high-leverage, late-game situations where a single call can have a greater impact on the final outcome. The low usage in early innings suggests teams prioritize saving challenges for critical moments rather than using them early when the game context is less decisive


## Situational Challenges

<img width="1108" height="568" alt="image" src="https://github.com/user-attachments/assets/505fbef8-9e85-4449-8907-65b623e73e2a" />
This bar chart shows the percentage of challenges used in baseball based on the situation, with the highest challenge rate occurring when the bases are loaded (nearly 4%). Conversely, challenges are least common when there are only men on base but not in scoring position (around 2.7%). The data suggests managers are most likely to use a challenge in the game's highest-leverage situation


<img width="1098" height="564" alt="image" src="https://github.com/user-attachments/assets/67b216f5-9b8f-464e-be0a-35a3068f18a6" />

his stacked bar chart analyzes the success rate of pitch challenges based on the challenger (batter vs. pitcher/catcher) and the base situation. Batters are significantly more successful in their challenges when runners are on base (up to 67.66% success when loaded), whereas they are least successful with empty bases. Conversely, the pitcher/catcher side is most successful challenging calls with empty bases (63.09% overturn rate), but their success rate drops notably once runners reach base. In the other hand, The data professionally indicates that the umpire's called strike zone may be less accurate or potentially favors the pitcher in high-leverage situations, evidenced by the batter's significantly higher success rate in overturning called strikes when runners are on base.


## Challenges by Leverage Index

<img width="1104" height="568" alt="image" src="https://github.com/user-attachments/assets/7de7182e-a140-4111-a5eb-914c02a9022c" />


This bar chart clearly demonstrates a positive correlation between the game's leverage level and the frequency of pitch challenges. Teams are most likely to utilize their challenges in high-leverage situations, with the challenge percentage peaking at approximately 12.5%. This pattern suggests that teams prioritize using their limited challenges when the outcome of a single pitch has the greatest potential impact on the game, compared to only around 9.0% in low-leverage scenarios.


## ABS Challenge Treatment Effect on OBP


To begin, I used the R function matchit() to match similar situations from the treatment group (i.e. triple-A 2024-2025 season) and the control group (i.e. double-A 2024-2025 season). I did a inital assessment of the treatment effect by looking at the avg OBP of each group for any level of leverage. 

<img width="460" height="72" alt="image" src="https://github.com/user-attachments/assets/58030ad0-e52d-4f4a-8da5-0418894cd42a" />

While the observed difference in On-Base Percentage (OBP) favors the treatment group (ABS challenge system), direct attribution of this increase to the intervention is difficult due to the confounding variable of competitive level disparity. Given that the pre-intervention difference in OBP between Double-A and Triple-A was 0.011 in 2021, the observed change in OBP may be heavily influenced by the inherent differences in hitter quality and performance between the two leagues, potentially masking or overstating the true effect of the ABS challenge system.


<img width="762" height="408" alt="image" src="https://github.com/user-attachments/assets/e85fd255-f0df-47c0-bfce-a19a81892b6a" />

Using a generalized linear model with a binomial family with a logit link function, I tried to find the effects of the ABS system. While the model estimates a minor positive impact of the ABS challenge system on OBP (an increase of $0.96$ percentage points), this treatment effect is not statistically significant ($p=0.24$). The model confirms that situational factors like game leverage and the presence of runners on base are highly significant determinants of a batter's success.


## ABS Challenge Treatment Effect on Win Probability

The ABS challenge system effect on OBP will be harder ot quantify considering the difference in quality between double-A and triple-A. However, the change in win-probability might be easier to quantify. 

<img width="602" height="68" alt="image" src="https://github.com/user-attachments/assets/44d29dc5-ac4d-40c0-897b-53223e52fc0b" />

Note that I am using the absolute value of WPA, which analyzes game volatility rather than directional impact on the home team. The inital assessment shows that the treatment group and the control group have basically similar WPA changes with very minimal differences. A linear model can assess the effect of the ABS system even more.

<img width="546" height="320" alt="image" src="https://github.com/user-attachments/assets/c212616a-b591-490f-b13f-7d947a6c2511" />

The treatment coefficient of -0.123 indicates that the ABS challenge system is associated with a 0.123 percentage point reduction in game volatility per at-bat. This means challenged at-bats produce smaller absolute swings in win probability compared to similar non-challenged situations. The ABS challenge system appears to moderate game volatility by reducing extreme win probability swings, potentially creating more predictable and fairer game outcomes where win probability changes reflect actual gameplay rather than officiating errors.


# Conclusion ⚾

The implementation of the ABS challenge system into MLB may seem like a momuental change but the effect it has on the game itself is rather minor. It is being integrated into the sport not as a disruptive force, but as a targeted tool for enhancing fairness. Through my analysis on its' use in triple-A, the ABS system is being used as it was intended accorind to Morgan Sword. Moments of high leverage such as late innings, bases-loaded or high leverage counts (3-2, 2-2, 1-2, etc) the ABS system is being used by players, not allowing a bad call by the umpire to heavily influence the game. The key finding is that the ABS system acts as a stabilizing force on game outcomes. My model indicates a statistically significant reduction in the absolute win probability change (WPA) in challenged at-bats, suggesting the system successfully mitigates the large, game-altering swings that can result from incorrect ball-strike calls. It reduces volatility by correcting consequential errors, and its use reflects the high-stakes, strategic decision-making that defines professional baseball. 



