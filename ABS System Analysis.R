library(baseballr)
library(dplyr)
library(lubridate)
library(zoo)
library(ggplot2)
library(segmented)
library(patchwork) 
library(cluster)
library(tidyr)
library(purrr)
library(stats)
library(stringr)
library(MatchIt)
library(cobalt)

x <- mlb_game_wp(753616)

minor_2025 <- mlb_schedule(season = 2025, level_ids = "11")
minor_2024 <- mlb_schedule(season = 2024, level_ids = "11")
minor_2024_2025 <- bind_rows(minor_2024, minor_2025)

double_a_2025 <- mlb_schedule(season = 2025, level_ids = "12")
double_a_2024 <- mlb_schedule(season = 2024, level_ids = "12")
double_a_2024 <- mlb_schedule(season = 2024, level_ids = "12")
double_a_2024_2025 <- bind_rows(double_a_2024,double_a_2025)

'last.pitch.of.ab' %in% colnames(reviewed_plays_pitch_context_2_1_counts)

double_a_pbp <- data.frame()
for (i in 2831:nrow(double_a_2024_2025)) {
  tryCatch({
    game_pbp <- data.frame(mlb_pbp(game_pk = as.integer(double_a_2024_2025[i,'game_pk'])))
    double_a_pbp <- bind_rows(double_a_pbp, game_pbp)
  }, error = function(e) {message(paste('No pbp in game id:', double_a_2024_2025[i,'game_pk'], e$message))})
}

double_a_filter <- double_a_pbp %>% filter(str_detect(game_date, "2025")) %>% filter(last.pitch.of.ab == 'true') %>%
  group_by(matchup.batter.id,matchup.batter.fullName) %>% summarise(at_bats = n())#196820
double_a_hits <- double_a_pbp %>% filter(str_detect(game_date, "2025")) %>% filter(last.pitch.of.ab == 'true') %>%
  group_by(result.event) %>% summarise(count = n())


minors_pbp <- data.frame()
for (i in 1:nrow(minor_2024_2025)) {
  tryCatch({
    game_pbp <- data.frame(mlb_pbp(game_pk = as.integer(minor_2024_2025[i,'game_pk'])))
    minors_pbp <- bind_rows(minors_pbp, game_pbp)
  }, error = function(e) {message(paste('No pbp in game id:', minor_2024_2025[i,'game_pk'], e$message))})
}

game_context <- data.frame()
game_pks <- unique(minors_pbp$game_pk)
for (i in game_pks) {
  minor_game <- mlb_game_linescore(i)
  minor_game <- minor_game %>% filter(num == 1)
  game_context <- bind_rows(game_context, minor_game)
}


reviewed_plays <- data.frame()
for (i in 1:nrow(minor_2024_2025)) {
  tryCatch({
    game_pbp <- data.frame(mlb_pbp(game_pk = as.integer(minor_2024_2025[i,'game_pk'])))
      if (any(game_pbp$details.hasReview == TRUE, na.rm = TRUE)) {
        game_pbp_filtered <- game_pbp %>% filter(details.hasReview == TRUE)
        reviewed_plays <- bind_rows(reviewed_plays, game_pbp_filtered)
      }
      else NULL
    }, error = function(e) {message(paste('No review in game id:', minor_2024_2025[i,'game_pk'], e$message))})
}

reviewed_plays_pitch <- reviewed_plays %>% filter(type == 'pitch') %>%
  mutate(original_call = case_when(
    reviewDetails.isOverturned == TRUE & details.description == 'Called Strike' ~ 'Ball',
    reviewDetails.isOverturned == TRUE & details.description == 'Ball' ~ 'Called Strike',
    TRUE ~ details.description
  ))


game_context <- data.frame()
game_pks <- unique(reviewed_plays_pitch$game_pk)
for (i in game_pks) {
  minor_game <- mlb_game_linescore(i)
  minor_game <- minor_game %>% filter(num == 1)
  game_context <- bind_rows(game_context, minor_game)
}


game_context_final <- game_context

reviewed_plays_pitch_context <- right_join(reviewed_plays_pitch, game_context_final)
plays_pitch_context <- right_join(minors_pbp, game_context)
plays_pitch_context <- data.frame(read.csv('pbp_minors.csv', header = TRUE))


# Convert list columns to character strings
plays_pitch_context_char <- plays_pitch_context
list_cols <- sapply(plays_pitch_context_char, is.list)

for(col in names(list_cols)[list_cols]) {
  plays_pitch_context_char[[col]] <- sapply(
    plays_pitch_context_char[[col]], 
    function(x) paste(x, collapse = ";")
  )
}

write.csv(plays_pitch_context_char, 'pbp_minors.csv')


plays_pitch_context_char_2 <- double_a_pbp
list_cols <- sapply(plays_pitch_context_char_2, is.list)

for(col in names(list_cols)[list_cols]) {
  plays_pitch_context_char_2[[col]] <- sapply(
    plays_pitch_context_char_2[[col]], 
    function(x) paste(x, collapse = ";")
  )
}

write.csv(plays_pitch_context_char_2, 'pbp_minors_AA.csv')

plays_pitch_context_2 <- plays_pitch_context %>%
  mutate(challenge_from = case_when(
    about.halfInning == 'bottom' & (reviewDetails.challengeTeamId == home_team_id) ~'batter',
    about.halfInning == 'top' & (reviewDetails.challengeTeamId == home_team_id) ~'pitcher/catcher',
    about.halfInning == 'bottom' & (reviewDetails.challengeTeamId == away_team_id) ~'pitcher/catcher',
    about.halfInning == 'top' & (reviewDetails.challengeTeamId == away_team_id) ~'batter'
  ))

plays_pitch_context$count

reviewed_plays_pitch_context_2 <- reviewed_plays_pitch_context %>%
  mutate(challenge_from = case_when(
    about.halfInning == 'bottom' & (reviewDetails.challengeTeamId == home_team_id) ~'batter',
    about.halfInning == 'top' & (reviewDetails.challengeTeamId == home_team_id) ~'pitcher/catcher',
    about.halfInning == 'bottom' & (reviewDetails.challengeTeamId == away_team_id) ~'pitcher/catcher',
    about.halfInning == 'top' & (reviewDetails.challengeTeamId == away_team_id) ~'batter'
  ))

reviewed_plays_pitch_context_2 <- data.frame(read.csv('ABS_Review.csv', header = TRUE))


reviewed_plays_pitch_context_2 <- reviewed_plays_pitch_context_2 %>% filter(reviewDetails.reviewType == "MJ",
                                                                            details.description %in% c("Called Strike", "Ball"))



review_success <- reviewed_plays_pitch_context_2 %>% group_by(challenge_from) %>%
  summarise(successful = sum(reviewDetails.isOverturned == TRUE, na.rm = TRUE),
            unsuccessful = sum(reviewDetails.isOverturned == FALSE, na.rm = TRUE),
            .groups = "drop") %>% pivot_longer(cols = c(successful, unsuccessful),
                                              names_to = "outcome",
                                              values_to = "count") %>%
  filter(count > 0)

review_success$total <- c(8673,8673,8105,8105)
review_success <- review_success %>% mutate(percentage = round(count/total *100),3)

ggplot(review_success, aes(x = challenge_from, y = count, fill = outcome)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = paste0(percentage,'%')), position = position_stack(vjust = 0.5), 
            color = "white", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("successful" = "blue", "unsuccessful" = "red")) +
  labs(
    title = "Review Success vs Unsuccessful by Challenger",
    subtitle = "Comparing overturn rates for batters and pitchers/catchers",
    fill = "Outcome"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 17, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "right",
    plot.tag = element_text(size=9)
  )


x <- c(-.95,.95,.95,-.95,-.95)
z <- c(1.6,1.6,3.5,3.5,1.6)

sz <- data_frame(x,z) 

reviewed_plays_pitch_context_2_1 <-  reviewed_plays_pitch_context_2


ggplot()+
  geom_path(data = sz, aes(x=x, y=z))+
  coord_equal()+
  xlab("feet from home plate")+
  ylab("feet above the ground") +
  coord_fixed(ratio = 1, xlim = c(-2, 2), ylim = c(0, 4.5)) +
  geom_density_2d_filled(data = reviewed_plays_pitch_context_2_1, aes(x=pitchData.coordinates.pX,
                                                                    y= pitchData.coordinates.pZ), alpha = 0.8) +
  labs(
    title = "Challenged Pitch Location Density by Batter and Pitcher Handedness",
    x = "Feet from Home Plate",
    y = "Feet Above the Ground"
  ) +
  facet_wrap(~matchup.batSide.code + matchup.pitchHand.code, ncol = 2) +
  theme_bw(base_size = 9) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 13)
  )


reviewed_plays_pitch_context_2_Overturned_batter <- reviewed_plays_pitch_context_2_1 %>%
  filter(reviewDetails.isOverturned == TRUE & challenge_from == 'batter')



ggplot()+
  geom_path(data = sz, aes(x=x, y=z))+
  coord_equal()+
  xlab("feet from home plate")+
  ylab("feet above the ground") +
  coord_fixed(ratio = 1, xlim = c(-2, 2), ylim = c(0, 4.5)) +
  geom_density_2d_filled(data = reviewed_plays_pitch_context_2_Overturned_batter, aes(x=pitchData.coordinates.pX,
                                                                      y= pitchData.coordinates.pZ), alpha = 0.8) +
  labs(
    title = "Overturned Batter Challenges Pitch Location Density",
    x = "Feet from Home Plate",
    y = "Feet Above the Ground"
  ) +
  facet_wrap(~matchup.batSide.code + matchup.pitchHand.code, ncol = 2) +
  theme_bw(base_size = 10) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 13)
  )


reviewed_plays_pitch_context_2_Overturned_pitcher <- reviewed_plays_pitch_context_2_1 %>%
  filter(reviewDetails.isOverturned == TRUE & challenge_from == 'pitcher/catcher')

ggplot()+
  geom_path(data = sz, aes(x=x, y=z))+
  coord_equal()+
  xlab("feet from home plate")+
  ylab("feet above the ground") +
  coord_fixed(ratio = 1, xlim = c(-2, 2), ylim = c(0, 4.5)) +
  geom_density_2d_filled(data = reviewed_plays_pitch_context_2_Overturned_pitcher, aes(x=pitchData.coordinates.pX,
                                                                                      y= pitchData.coordinates.pZ), alpha = 0.8) +
  labs(
    title = "Overturned Pitcher/Catcher Challenges Pitch Location Density",
    x = "Feet from Home Plate",
    y = "Feet Above the Ground"
  ) +
  facet_wrap(~matchup.batSide.code + matchup.pitchHand.code, ncol = 2) +
  theme_bw(base_size = 10) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 13)
  )


reviewed_plays_pitch_context_2_1_counts <- reviewed_plays_pitch_context_2_1 %>%
  mutate(challenge.count.ball = case_when((reviewDetails.isOverturned == FALSE) ~ count.balls.start,
                                          (reviewDetails.isOverturned == TRUE & original_call == 'Ball') ~ count.balls.start + 1,
                                          (reviewDetails.isOverturned == TRUE & original_call == 'Called Strike') 
                                          ~ count.balls.start -1),
         challenge.count.strike = case_when((reviewDetails.isOverturned == FALSE) ~ count.strikes.start,
                                            (reviewDetails.isOverturned == TRUE & original_call == 'Ball') ~ count.strikes.start -1,
                                            (reviewDetails.isOverturned == TRUE & original_call == 'Called Strike') 
                                            ~ count.strikes.start + 1))

abs_review_games <- unique(reviewed_plays_pitch_context_2_1_counts$game_pk)
plays_pitch_context_2 <- plays_pitch_context_2 %>% filter(game_pk %in% abs_review_games)
plays_pitch_context_2_1 <- plays_pitch_context_2 %>% filter(isPitch == TRUE)
plays_pitch_context_2_1 <- plays_pitch_context_2_1 %>% filter(details.description %in% c("Called Strike", "Ball"))

challenged_count <- reviewed_plays_pitch_context_2_1_counts %>%
  group_by(challenge_from, challenge.count.ball, challenge.count.strike, .groups = TRUE) %>%
  summarise(count = n())

clean_challenged_count <- na.omit(challenged_count)
clean_challenged_count <- clean_challenged_count %>%
  mutate(pitch_count = paste(challenge.count.ball, challenge.count.strike, sep = "-"))

challenged_count <- reviewed_plays_pitch_context_2_1_counts %>%  
  mutate(pitch_count = paste(challenge.count.ball, challenge.count.strike, sep = "-")) %>%
  filter(!pitch_count == "NA-NA") %>% group_by(pitch_count) %>% summarise(count_challenged = n())


total_counts <- plays_pitch_context_2_1 %>% 
  mutate(pitch_count = paste(count.balls.start, count.strikes.start, sep = "-")) %>%
  filter(isPitch == TRUE) %>% group_by(pitch_count) %>% summarise(count_total = n())

counts_join <- inner_join(total_counts,challenged_count, by = 'pitch_count')
counts_join <- counts_join %>% 
  mutate(percentage_challenged = count_challenged/count_total * 100)

ggplot(counts_join, aes(x=pitch_count, y = percentage_challenged)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Pitch Count', y = "Percentage", title = 'Challenges per Pitch Count') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

ggplot(challenged_count, aes(x=pitch_count, y = count_challenged)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Pitch Count', y = "Count", title = 'Challenges per Pitch Count') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))


challenged_count_2 <- reviewed_plays_pitch_context_2_1_counts %>%  
  mutate(pitch_count =paste(challenge.count.ball, challenge.count.strike, sep = "-")) %>%
  group_by(challenge_from, pitch_count, .groups = TRUE) %>%
  summarise(count_challenged = n())

counts_join_2 <- inner_join(total_counts,challenged_count_2, by = 'pitch_count')
counts_join_2 <- counts_join_2 %>% 
  mutate(percentage_challenged = count_challenged/count_total * 100)

check <- counts_join_2 %>% group_by(challenge_from) %>% summarise(r = sum(count_challenged))


ggplot(counts_join_2, aes(x=pitch_count, y = percentage_challenged)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Pitch Count', y = "Percentage", title = 'Challenges per Pitch Count by Challenger (Percentage)') +
  facet_wrap(~challenge_from, nrow = 2) +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

ggplot(challenged_count_2, aes(x=pitch_count, y = count_challenged)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Pitch Count', y = "Count", title = 'Challenges per Pitch Count by Challenger (Count)') +
  facet_wrap(~challenge_from, nrow = 2) +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))


by_inning_challenge <- reviewed_plays_pitch_context_2_1_counts %>% filter(!about.inning %in% c(10, 11, 12, 13)) %>%
  group_by(about.inning)  %>% summarise(count = n())

total_counts_by_inning <- plays_pitch_context_2_1 %>% filter(!about.inning %in% c(10, 11, 12, 13)) %>%
  group_by(about.inning) %>% summarise(count_total = n())


by_inning <- inner_join(by_inning_challenge,total_counts_by_inning,by = join_by(about.inning))
by_inning <- by_inning %>% mutate(percentage = count/count_total * 100)
by_inning$about.inning <- as.factor(by_inning$about.inning)

ggplot(by_inning, aes(x=about.inning, y = percentage)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Inning', y = "Percentage", title = 'Challenges by Inning (Percentage)') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

ggplot(by_inning, aes(x=about.inning, y = count)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Inning', y = "Count", title = 'Challenges by Inning (Count)') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))


by_situation <- reviewed_plays_pitch_context_2_1_counts  %>%
  group_by(game_pk, about.atBatIndex, matchup.splits.menOnBase) %>% summarise(count = n()) %>%
  group_by(matchup.splits.menOnBase) %>% summarise(count = sum(count))

total_counts_by_situation <- plays_pitch_context_2_1 %>%
  group_by(game_pk, about.atBatIndex, matchup.splits.menOnBase) %>% summarise(count = n()) %>%
  group_by(matchup.splits.menOnBase) %>% summarise(count_total = sum(count))

by_situation_percent <- inner_join(by_situation,total_counts_by_situation,by = join_by(matchup.splits.menOnBase)) %>%
  mutate(percentage = count/count_total * 100)

by_situation_percent$matchup.splits.menOnBase <- factor(
  by_situation_percent$matchup.splits.menOnBase,
  levels = c("Empty", "Men_On", "RISP", "Loaded")
)

ggplot(by_situation_percent, aes(x=matchup.splits.menOnBase, y = count)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Situation', y = "Count", title = 'Challenges  by Situation (Count)') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

ggplot(by_situation_percent, aes(x=matchup.splits.menOnBase, y = percentage)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Situation', y = "Percentage", title = 'Challenges by Situation (Percentage)') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

by_situation_2 <- reviewed_plays_pitch_context_2_1_counts  %>%
  group_by(game_pk, about.atBatIndex, matchup.splits.menOnBase, reviewDetails.isOverturned) %>%
  summarise(count = n()) %>%
  group_by(matchup.splits.menOnBase,reviewDetails.isOverturned) %>% summarise(count_2 = sum(count)) %>%
  inner_join(by_situation, by = 'matchup.splits.menOnBase') %>% mutate(percentage = round(count_2/count * 100,2))

ggplot(by_situation_2, aes(x=matchup.splits.menOnBase, y = count, fill = reviewDetails.isOverturned)) +
  geom_bar(stat = 'identity') +
  geom_text(aes(label = paste0(percentage,'%')), position = position_stack(vjust = 0.5), 
            color = "white", fontface = "bold", size = 5) +
  labs(x = 'Pitch Count', y = "Percentage", title = 'Challenges by Situation') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

total_by_batter <- reviewed_plays_pitch_context_2_1_counts  %>% 
  group_by(game_pk, about.atBatIndex, matchup.splits.menOnBase, challenge_from) %>%
  summarise(count = n()) %>% group_by(matchup.splits.menOnBase,challenge_from) %>%
  summarise(count = sum(count))

by_situation_by_challenger <- reviewed_plays_pitch_context_2_1_counts  %>% 
  group_by(game_pk, about.atBatIndex, matchup.splits.menOnBase, challenge_from, reviewDetails.isOverturned) %>%
  summarise(count = n()) %>%
  group_by(matchup.splits.menOnBase,challenge_from,reviewDetails.isOverturned) %>% summarise(count_2 = sum(count)) %>%
  inner_join(total_by_batter, by = c('matchup.splits.menOnBase','challenge_from')) %>% mutate(percentage = round(count_2/count * 100,2))

ggplot(by_situation_by_challenger, aes(x = matchup.splits.menOnBase, y = count_2, fill = reviewDetails.isOverturned)) +
  geom_bar(stat = 'identity') +
  geom_text(aes(label = paste0(percentage, '%')), 
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 3) +
  labs(x = 'Men on Base Situation', 
       y = "Challenge Count", 
       title = 'Challenges by Situation by Challenger') +
  facet_wrap(~challenge_from, nrow= 2) +  # ✅ corrected
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.5),
        axis.title = element_text(size = 10))

reviewed_plays_pitch_context_2_1_counts_model <- reviewed_plays_pitch_context_2_1_counts %>%
  mutate(pitch_count = as.factor(paste(challenge.count.ball, challenge.count.strike, sep = "-")))
  

model <- glm(reviewDetails.isOverturned ~ challenge_from +
               pitch_count + matchup.batSide.description + matchup.pitchHand.description,
             data = reviewed_plays_pitch_context_2_1_counts_model, family = binomial(link = 'logit'))
summary(model)

leverage_data <- data.frame()
double_a_leverage_data <- data.frame()
double_a_games <- double_a_2024_2025$game_pk
for (i in 1:length(double_a_games)) {tryCatch({
  leverage <- mlb_game_wp(double_a_games[i])
  leverage$game_pk <- double_a_games[i]
  double_a_leverage_data <- bind_rows(double_a_leverage_data,leverage)
}, error = function(e) {message(paste('No pbp in game id:', double_a_games[i], e$message))})
}

leverage_reviewed_plays <- inner_join(
  reviewed_plays_pitch_context_2_1_counts,
  leverage_data,
  by = c("about.atBatIndex" = "at_bat_index", "game_pk" = "game_pk")
)

leverage_reviewed_plays <- leverage_reviewed_plays %>% mutate(leverage_group = case_when(
  leverage_index <= 0.85 ~ 'Low',
  leverage_index > 0.85 & leverage_index < 2 ~ 'Medium',
  leverage_index >= 2 ~ 'High',
  is.na(leverage_index) == TRUE ~ 'First Batter'
))

leverage_reviewed_plays_count <- leverage_reviewed_plays %>% group_by(leverage_group) %>%
  summarise(count = n())

leverage_reviewed_plays_count$leverage_group <- factor(
  leverage_reviewed_plays_count$leverage_group,
  levels = c("First Batter", "Low", "Medium", "High")
)

leverage_plays <- inner_join(plays_pitch_context_2, leverage_data,
                             by = c("about.atBatIndex" = "at_bat_index", "game_pk" = "game_pk")) %>%
  filter(last.pitch.of.ab == 'true' | (last.pitch.of.ab == 'true' & about.atBatIndex == 0))

leverage_plays <- leverage_plays %>% mutate(leverage_group = case_when(
  leverage_index <= 0.85 ~ 'Low',
  leverage_index > 0.85 & leverage_index < 2 ~ 'Medium',
  leverage_index >= 2 ~ 'High',
  is.na(leverage_index) == TRUE ~ 'First Batter'
))

leverage_plays_count <- leverage_plays %>% group_by(leverage_group) %>%
  summarise(total_count = n())

leverage_plays_count$leverage_group <- factor(
  leverage_plays_count$leverage_group,
  levels = c("First Batter", "Low", "Medium", "High")
)


percentage_leverage <- inner_join(leverage_plays_count,leverage_reviewed_plays_count,
                                  by = 'leverage_group') %>% mutate(percentage = count/total_count * 100)



ggplot(leverage_reviewed_plays_count, aes(x=leverage_group, y = count)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Leverage', y = "Count", title = 'Challenges Count by Leverage Level') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))

ggplot(percentage_leverage, aes(x=leverage_group, y = percentage)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  labs(x = 'Leverage', y = "Percentage", title = 'Challenges Percentage by Leverage Level') +
  theme_minimal() +
  theme(plot.title = element_text(size = 17, hjust = 0.50),
        axis.title = element_text(size = 10))


leverage_double_a_pbp <- inner_join(double_a_pbp, double_a_leverage_data,
                                    by = c("about.atBatIndex" = "at_bat_index", "game_pk" = "game_pk"))
leverage_double_a_pbp <- leverage_double_a_pbp %>% filter(last.pitch.of.ab == 'true') 

triple_a_challenged <- leverage_reviewed_plays %>% mutate(treatment =1, league = 'AAA',
                                                          score_diff = abs(result.awayScore-result.homeScore),
                                                          home_team_win_probability_added_2 = abs(home_team_win_probability_added)) %>%
  dplyr::select(game_pk,about.atBatIndex,about.inning,matchup.splits.menOnBase,count.outs.start,
         leverage_index,score_diff,treatment,league,home_team_win_probability_added_2, result.eventType)

double_a_all <- leverage_double_a_pbp %>% mutate(treatment =0, league = 'AA',
                                                          score_diff = abs(result.awayScore-result.homeScore),
                                                 home_team_win_probability_added_2 = abs(home_team_win_probability_added)) %>%
  dplyr::select(game_pk,about.atBatIndex,about.inning,matchup.splits.menOnBase,count.outs.start,
                leverage_index,score_diff,treatment,league,home_team_win_probability_added_2, result.eventType)

match_data <- bind_rows(triple_a_challenged, double_a_all) %>% filter(!is.na(leverage_index)) %>% distinct()



write.csv(match_data, 'match_data.csv', row.names = FALSE)

match_model <- matchit(
  treatment ~ 
    leverage_index +           # Game importance
    about.inning +                   # Game timing
    score_diff +          # Game closeness (absolute value)
    count.outs.start +                     # Out state
    matchup.splits.menOnBase +               # Runner configuration
    about.atBatIndex +
    I(leverage_index * about.inning),        # Count situation
  data = match_data,
  method = "nearest", 
  distance = "glm",           # Use propensity scores
  ratio = 1,                  # 1 control per treatment
  caliper = 0.2,              # Prevent poor matches
  mahvars = ~ leverage_index + about.inning + score_diff # Mahalanobis matching on key vars
)


matched_data <- match.data(match_model)

# Check balance numerically
bal_table <- bal.tab(match_model)
print(bal_table)

treatment_effect <- matched_data %>%
  group_by(treatment) %>%
  summarise(
    n = n(),
    mean_wpa_change = mean(abs(home_team_win_probability_added_2)),
    sd_wpa_change = sd(abs(home_team_win_probability_added_2)),
    median_wpa_change = median(abs(home_team_win_probability_added_2)),
    avg_leverage = mean(leverage_index)
  )

t_test_result <- t.test(home_team_win_probability_added_2 ~ treatment, data = matched_data)
print(t_test_result)

effect_model <- lm(home_team_win_probability_added_2 ~ treatment + 
                     leverage_index + about.inning + abs(score_diff),
                   data = matched_data, 
                   weights = weights) 

summary(effect_model)

plot(matched_data$leverage_index,matched_data$home_team_win_probability_added_2)

matched_data_high_leverage <- matched_data %>% filter(leverage_index >= 2.0)

treatment_effect <- matched_data_high_leverage %>%
  group_by(treatment) %>%
  summarise(
    n = n(),
    mean_wpa_change = mean(abs(home_team_win_probability_added_2)),
    sd_wpa_change = sd(abs(home_team_win_probability_added_2)),
    median_wpa_change = median(abs(home_team_win_probability_added_2)),
    avg_leverage = mean(leverage_index)
  )

effect_model <- lm(home_team_win_probability_added_2 ~ treatment + 
                     leverage_index + about.inning + abs(score_diff),
                   data = matched_data_high_leverage, 
                   weights = weights) 


summary(effect_model)


matched_data <- matched_data %>%
  mutate(on_base = ifelse(result.eventType %in% 
                            c("single", "double", "triple", "home_run", 
                              "walk", "intent_walk", "hit_by_pitch", 
                              "field_error"), 
                          1, 0)) %>% filter(!result.eventType %in% c("pickoff_caught_stealing_2b",
                                                                     "pickoff_3b","caught_stealing_home",
                                                                     "caught_stealing_3b", "caught_stealing_2b",
      
                                                                                                                                    "pickoff_1b", "catcher_interf"))

obp_analysis <- matched_data %>%
  group_by(treatment) %>%
  summarise(
    n_at_bats = n(),
    n_reached_base = sum(on_base, na.rm = TRUE),
    obp = mean(on_base, na.rm = TRUE),
    avg_leverage = mean(leverage_index)
  )

glm_model <- glm(on_base ~ treatment + 
                   leverage_index + matchup.splits.menOnBase + score_diff,
                 data = matched_data, family = binomial(link='logit'),
                 weights = weights)

summary(glm_model)

coef(glm_model)["treatment"]

treatment_effect_logit <- coef(glm_model)["treatment"]
treatment_effect_prob <- exp(treatment_effect_logit) / (1 + exp(treatment_effect_logit)) - 0.5
cat("Estimated OBP increase from challenges:", round(treatment_effect_prob * 100, 2), "percentage points\n")


matched_data_3 <- matched_data %>% filter(leverage_index < 5) %>%
  mutate(leverage_group = cut(leverage_index,
                              breaks = seq(0,max(leverage_index), by = 0.5))) %>%
  group_by(treatment, leverage_group) %>%
  summarise(count = n(), obp = mean(on_base, na.rm = TRUE),.groups = 'drop') 


ggplot(matched_data_3, aes(x = leverage_group, y = obp)) +
  geom_bar(stat = 'identity', fill="steelblue") +
  facet_grid(~treatment)
  



