## This project implement such a demographic model for England and Wales, 
## to predict the expected number of deaths per week from the beginning of 2020
## if death rates had stayed at the levels seen in 2017-19. The model will
## include an adjustment to allow for seasonal variation in mortality rates. 
## compare this to the actual deaths per week that occurred over this period1,
## to obtain an excess deaths time series, and then model this series using
## a simple Bayesian model in JAGS.

## set the path
## setwd("/Users/ivan/Desktop/S1/Statistical Programming/in project/project5")
## import two files as our data set 
pop_df <- read.table('lt1720uk.dat')
death_df <- read.table('death1722uk.dat')

## task 1
## define function to predict deaths by week 
predict_death <- function(fpop,mpop,mf,mm,d){
  ## expected proportion of Ni dying in a week for male and female
  qm <- 1-exp(-mm/52)
  qf <- 1-exp(-mf/52)
  ## set initial birth rate for male and female
  birth_mrate <- mpop[1]  
  birth_frate <- fpop[1]
  ## create an array to store the death population for each week
  death_pop <- c()   
  
  for (i in 1:length(d)){
    ## calculate the death population each week for different age class
    Df <-  0.9885 *d[i]*fpop*qf
    Dm <-  0.9885 *d[i]*mpop*qm
    
    ## calculate the survivors each week for different age class
    Nstarm <- mpop - Dm
    Nstarf <- fpop - Df
  
    ## calculate the population of age class 0-1 by birth rate
    mpop[1] <- 51/52 *  Nstarm[1] + 1/52 * birth_mrate 
    fpop[1] <- 51/52 *  Nstarf[1] + 1/52 * birth_frate
    
    ## calculate the number of post-ageing people in the new week 
    for (j in 2:101){
      mpop[j] <-  51/52 * Nstarm[j]+ 1/52 * Nstarm[j-1]
      fpop[j] <-  51/52 * Nstarf[j]+ 1/52 * Nstarf[j-1]
    }
    ## get the summation of male and female death population
    death_pop[i] <-  sum(Df + Dm)
  }
  ## output the predicted deaths array
  death_pop
}

## set the initial population for male and female in 2017
fpop <- pop_df$fpop17
mpop <- pop_df$mpop17
## set the annual death rates 
mf <- pop_df$mf
mm <- pop_df$mm
## get the mortality rate modifier 2017 to 2019
d <- death_df$d[1:156]
## get the real deaths and predicted deaths of 2017 to 2019
real_deaths <- death_df$deaths[1:156]
predict_deaths <- predict_death(fpop,mpop,mf,mm,d)
## compare the two values
sum(real_deaths-predict_deaths)

## task 2
## set the initial population for male and female in 2020
fpop <- pop_df$fpop20
mpop <- pop_df$mpop20
## calculate the total number of weeks in the dataset
week_length <- length(death_df$d)

## get the mortality rate modifier overall
d_all <- death_df$d[157:week_length]
## calculating the overall predicted and real number of deaths
death_pred_all <- predict_death(fpop,mpop,mf,mm,d_all)
death_real_all <- death_df$deaths[157:week_length]
## calculating the excess deaths
excess_deaths_all <- sum(death_real_all-death_pred_all)

## get the mortality rate modifier for 2020
d_2020 <- death_df$d[157:(157+51)]
## calculating the predicted and real number of deaths for 2020
death_pred_2020 <- predict_death(fpop,mpop,mf,mm,d_2020)
death_real_2020 <- death_df$deaths[157:(157+51)]
## calculating the excess deaths
excess_deaths_2020 <- sum(death_real_2020-death_pred_2020)


## task 3 
## define the number in 2020 and overall in title
title_name <- paste("Excess deaths for 2020:",round(excess_deaths_2020,0),
                    " Excess deaths overall:",round(excess_deaths_all,0))
week <- c(1:length(death_pred_all)) ## define the week for x-axis 
## plot the predicted death overall  
plot(week, death_pred_all, type="l",col='blue',
     ylim = c(0,25000), ylab = 'Deaths', main = title_name)
## plot the real death overall  
lines(week, death_real_all, type="l",col='red',ylim = c(0,25000))


## task 4
## calculate the vector of excess deaths by week 
excess_death <- death_real_all-death_pred_all
## get the cumulative excess deaths vector
cum_death <- cumsum(excess_death)
## draw the plot about cumulative excess deaths by week
plot(week, cum_death, type="l", ylab = 'Cumulative excess deaths',
       main = 'Cumulative excess deaths by week')

## task 5
## import the rjags package
library(rjags)
## set value of excess deaths in some weeks to NA
holiday_week <- c(51, 52, 53,105, 106)
excess_death[holiday_week] = NA
## compile the jags model
mod <- jags.model("model.jags",
                  data=list(x=excess_death, N=length(excess_death)))

## task 6
## sampling the model by 10000 iterations 
sam<- jags.samples(mod,c("mu","tau","kapa","rou","alpha"),n.iter=10000)
## draw the trace plot model of rou
plot(sam$rou, type='l',ylab=expression(rou), main = 'Trace plot of p')
## draw the histograms of rou
hist(sam$rou, xlab=expression(rou), main = 'Histograms of p')

## task 7
## create an array to store the mu
expected_mu <- c()
for (i in week){
  ## add the mean value of 10000 iterations to each expected mu
  expected_mu[i] <- mean(sam$mu[i,,])  
}
  
## task 8
## sampling every 50th sampled mu vector
mu_sample <- sam$mu[week,1:200*50,1]
## plot the first 50th sampling
plot(week,mu_sample[,1],type='l',col = 'grey',
     ylim = c(-5000,15000),ylab='mu', main = 'sampling mu plot')
## plot the other 50th sampling
for (i in 2:200){
  lines(week,mu_sample[,i],col = 'grey')
}
## plot the expected value for mu
lines(week, expected_mu, col= 'blue')
## add the observed excess deaths
points(week[-holiday_week],excess_death[-holiday_week],col='black')
## add xis not used for inference
points(holiday_week,(death_real_all-death_pred_all)[holiday_week],col='red')

## task 9
## use excess death minus expected value vector for µ to get the residuals
residuals <-  excess_death- expected_mu
## draw the residuals plot
plot(week, residuals, main='residuals plot')


