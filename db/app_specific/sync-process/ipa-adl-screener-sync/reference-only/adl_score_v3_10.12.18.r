##############################################################
######## SCORING ALGORITHM FOR ADCS ADL REDCAP SURVEY ########
##############################################################
library(tidyverse)
library(redcapAPI)

#Establish API connection to Partners REDCap project
#adlcon <- redcapConnection(url = "http://redcap.fphs.harvard.edu/api/",
                                  #token = "", config = NULL)

#API pull records for adcs completers and store as dataframe
#adl_df <- exportRecords(adlcon, forms = c("adcs_npiq"), survey = TRUE)

#Read in adcs data exported from REDCap
setwd("C:/Users/dam40/Desktop")
adl_df <- read.csv("adcsdata.csv")

#Isolate variables used to create the ADL total score (0-78)
adl_sc <- adl_df %>%
  select(subject_id, adl_eat, adl_walk, adl_toilet, adl_bath, adl_groom,
         adl_dressa_perf, adl_dressb, adl_phone_perf, adl_tva,
         adl_tvb, adl_tvc, adl_attnconvo_part, adl_dishes_perf,
         adl_belong_perf, adl_beverage_perf, adl_snack_prep,
         adl_garbage_perf, adl_travel_perf, adl_shop_select,
         adl_shop_pay, adl_appt_aware, adl_alone_15m, adl_alone_gt1hr,
         adl_alone_lt1hr, adl_currev_tv, adl_currev_outhome,
         adl_currev_inhome, adl_read_lt1hr, adl_read_gt1hr,
         adl_write_complex, adl_hob_perf, adl_appl_perf)

#Isolate variables used to count number of "don't know" respsonses
adl_dk <- adl_df %>%
  select(subject_id, adl_dressa, adl_phone, adl_tv, adl_tva, adl_tvb,
         adl_tvc, adl_attnconvo, adl_dishes, adl_belong,
         adl_beverage, adl_snack, adl_garbage, adl_travel,
         adl_shop, adl_shop_pay, adl_appt, adl_alone,
         adl_alone_15m, adl_alone_gt1hr, adl_alone_lt1hr,
         adl_currev, adl_currev_tv, adl_currev_outhome,
         adl_currev_inhome, adl_read, adl_read_lt1hr,
         adl_read_gt1hr, adl_write, adl_hob, adl_appl)

#Replace overlapping values not required for the two calculations (score and don't know count)
adl_sc[adl_sc == 9] <- 0  #Replaces "don't know" overlap w/ 0 to calculate total adl score
adl_dk[adl_dk < 9]  <- 0  #Replaces non "don't know" overlap with 0 for "don't know" count
adl_dk[adl_dk == 9] <- 1  #Replaces all don't know (9) with 1 for don't know count

adl_sc$total_score <- rowSums(adl_sc[,2:33], na.rm = TRUE)  #ADL summary score
adl_dk$dk_count <- ((rowSums(adl_dk[,2:31], na.rm = TRUE))) #Don't know count

#Select don't know counts and total scores; join by "subject_id"
adl_sc <- select(adl_sc, subject_id, total_score) #Select columns from score table
adl_dk <- select(adl_dk, subject_id, dk_count)    #Select columns from don't know table
adl_summary <- inner_join(adl_sc, adl_dk, by = "subject_id") #Join two scores into one df by rc survey identifier

#Write summary report to table 
write.csv(adl_summary, row.names = FALSE,
          file = "adl_summary.csv") #csv at the moment
