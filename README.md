# Practical 5 (Individual): UK excess deaths 2020-22
‘Excess deaths’ are the number of deaths over some period, relative to what would have been expected given
data for some previous period. One way to get the expected number of deaths, for the UK say, is to take an average
over the previous 5 years. Since death rates have a seasonal pattern, with more deaths in the winter, it is usual to
average by week of the year. i.e. to compute the expected number of deaths in week 1 of the year, week 2, week 3
and so on. The obvious problem with such averages is that they will underestimate the number of deaths we should
expect if the population is growing and/or ageing.

Less problematic is to compute the expected number of deaths from data on the annual probability of death for
each one year age group, coupled with the populations of each age group at the start of the period of interest. In
the UK both sets of data are available from the Office for National Statistics (ONS). The probability of death data
are based on 3 year periods (e.g. 2017-2019). Given these data we can simply apply the dying and ageing process
to update the population in each age group and obtain the expected number of deaths each week. That is we iterate
a basic demographic model for the population in which the death process is based on the age specific death rates
observed over the previous 3 years. That way we get the expected number of deaths if death rates stay the same,
but without assuming that the population has stayed constant, or that the population is not ageing.

In this practical you will implement such a demographic model for England and Wales, to predict the expected
number of deaths per week from the beginning of 2020 if death rates had stayed at the levels seen in 2017-19. The
model will include an adjustment to allow for seasonal variation in mortality rates. You will then compare this to
the actual deaths per week that occurred over this period1, to obtain an excess deaths time series, and then model
this series using a simple Bayesian model in JAGS.

The population model will have 101 age classes - from age 0 to age 100. Let Ni be the population in age class
i. For each age class we have the instantaneous per capita death rate per year mi
. If an age class has population Ni at the start of the year, it will have population Nie−mi at the year end. 
In the absence of seasonality, if the population is Ni at the start of a week it will be Nie−mi/52 at the end of 
the week. Hence the expected proportion of Ni dying in a week is qi = 1 − e−mi/52. In reality there is seasonality 
in the death rates. A simple model is that the proportion dying is dj qi in week j, where dj can be computed from
previous data. So for week j the model becomes
$$D_i = d_jq_iN_i, N_i^* = N_i − D_i, N_i^+ = N_i^* 51/52 + N_i^* −1/52, i = 1, . . . , 101$$
Assuming a constant birth rate, we can set N0 to the initial value of the age 0 population, i.e. the value of N1 at
the start of simulation. If Ni is the population in age class i at the start of week j then Ni+ is the population in the
same age class at the start of week j + 1, while Di is the number of deaths in that age class over week j. So each
week the model first computes the deaths and reduces the populations appropriately, and then applies the ageing
process, moving 1/52th of the population of an age class up an age band. The ageing model is a little crude, just to
avoid you having to store weekly age classes instead of yearly ones: the crudeness makes very little difference to
the results here, but leads to slightly overstating the number of deaths. Changing the model to $D_i = 0.9885d_jq_iN_i$
corrects this.

By summing up the Di over age classes, you get the predicted number of deaths each week. The mi are rather
different between men and women, so the above model needs to be run separately for each sex, and the resulting
weekly predicted deaths summed. On the Learn page are two text files of data. lt1720uk.dat contains columns

• age - the age classes 0:0-1 years, 1: 1-2 years, etc.

• fpop17 and mpop17 - the female and male populations in each 1 year age class at the start of 2017.

• fpop20 and mpop20 - the same for the start of 2020.

• mf and mm - female and male annual death rates for each 1-year age band, computed from 2017-19 data.
death1722uk.dat contains columns

• deaths the number of deaths that week.

• week the week since the start of 2017. 2020 starts in week 157.

• d the mortality rate modifier, dj , value for that week.
