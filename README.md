# [UNDER CONSTRUCTION]
# Visualizing the danger of multiple t-test comparisons
## 1. Abstract
This repository contains a function, `false_pos`, for quantifying the false positive error rate with multiple t-tests. For a given number of groups and observations per group, the function creates `n_groups` samples from the same (Gaussian) parent distribution, each with `n_obs` observations. Because these samples are drawn from the same population, any differences between them should not be statistically significant (i.e. p > 0.05). 

The function then performs an ANOVA and all possible pairwise t-tests. The lowest pairwise t-test p-value and the ANOVA p-value are recorded. This is done `n_iter` times to form distributions of p-values for t-tests and ANOVAs, which are then plotted if `figure = T`. If `pretty = T`, the proportion of iterations with p-values below 0.05 is printed; otherwise, a list is returned with summary statistics.

The functional arguments are listed below:
* `n_groups`: the number of groups in the comparison
* `n_obs`: the number of observations per group
* `n_iter`: the number of iterations for creating the distribution of p-values
* `figure`: should a figure be printed?
* `pretty`: should the output be simple (pretty = T) or thorough (pretty = F)?
* `verbose`: as the function is running, should the progress be printed?

## 2. Background
### 2a. Motivation
Many research questions involve comparing experimental groups to one another. The Dutch have an international reputation for their height, but is the average person from the Netherlands actually taller than people from, say, France or Sweden? 

One way to find out is to measure every person in each of these three countries. (We'd have to measure quickly to account for birth and death rates!) With all 17.2 million, 66.9 million, and 9.9 million people carefully catalogued in our Excel file, we can take the mean of each group (representing the average height) and finally rest knowing whether the Dutch are, indeed, the tallest Europeans.

<img align="right" src="https://i.imgur.com/JbXsczj.png"> One issue: censusing this many people is an insane amount of work. Thanks to statistics, we can reach the same conclusion much faster with less effort. At its core, statistics is about making inferences about a **population** from a **sample**. We don't need to measure every single Swede - we can measure a subset (our *sample*), and provided we're sampling randomly and independently, our sample will quickly become an accurate representation of all of Sweden (our *population*). 

Alright, so we go out and sample 50 random people from each country. We plot our data and see that the distributions of heights look different, and the sample means indeed are a bit different... but are these differences meaningful? Unlike with our census of the entire population of each country, because we're dealing with a *subset*, we have to take into account *randomness* in our sampling. Our samples are *representations* of the populations, but of course you're going to distort the image a bit when you condense 66.9 million people into 50. *How much* of a difference in our samples do we need to see before we can declare the tallest Europeans?

### 2b. t-tests and ANOVAs
A commonly-used method for comparing two groups is the **[t-test](https://en.wikipedia.org/wiki/Student%27s_t-test)**. t-tests are a simple, powerful tool (assuming the required assumptions are met in the data), and they're a staple of introductory statistics courses. In short, a t-test quantifies the probability that *the populations* two samples are drawn from have the same mean. The sample means might differ, but a t-test translates that difference into an inference on the populations.

A t-test returns a [p-value](https://en.wikipedia.org/wiki/P-value): the probability, given the two population means are identical, that you'd get your difference in sample means (or greater). This accounts for the variability that sampling introduces into our analysis: yes, our sample means might be different, but of course you'll get some differences between this random group of 50 French people versus the next random group of 50 French people. You'd expect a high p-value when you compare two samples from the same population: the samples are different but the t-test believes they're coming from the same population. If we have a huge difference between samples, though, we would get a low p-value: the t-test believes it's unlikely these samples came from have populations with identical means. 

*(The true definition of a p-value is a little more complicated because this is frequentist statistics: assuming the two populations have identical means, if you ran your experiment thousands of times, it's the proportion of samples that would have at least as large a difference in sample means.)*

This all works well for comparing two groups, but when we compare more than two groups, we need to perform an [analysis of variance](https://en.wikipedia.org/wiki/Analysis_of_variance). For our heights example, it can be tempting to run three t-tests: comparing the Dutch heights to French heights, Dutch heights to Swedish heights, and French heights to Swedish heights. This, however, is dangerous: **multiple t-tests inflate the probability of (falsely) declaring that the two population means are different, when they actually aren't.** An ANOVA avoids this problem by restating the question as "are the means of *all* populations equal?"

## 3. Results
### 3.1 Visualizing false positive rates
We can use our custom function `false_pos` to easily visualize the problems of running multiple t-tests. Our function creates multiple groups that are sampled from the same population, so they should all be identical. This should be reflected in having a t-test and ANOVA p-value above 0.05. Because there's randomness in what exact numbers are drawn for each sample, let's run this process 10,000 times to get a feel for the *distribution* of possible answers we could get. Let's do this for three groups with ten observations each.

![](https://i.imgur.com/jeP6YNm.png)

Above, we see the distribution of p-values for running multiple t-tests (gray) and the ANOVA (blue). For this run, `false_pos` tells us that running multiple t-tests gives you a false positive rate of 11.4%, whereas the ANOVA is 4.8%. We should expect a false positive rate of about 5%, which we get with ANOVA, but we have more than double the error rate with multiple t-tests.

### 3.2 Changing number of observations and groups
What if we change the number of observations or the number of groups? On the one hand, we should expect to increase the t-test false positive rate when we increase the number of comparisons. But what if we have more data per group? If we have a better picture of the parent population each sample comes from, will the t-test get better at recognizing that the samples are coming from the same place? 

To answer these questions, we can run set ranges on `n_obs` and `n_groups`, then run `false_pos` on each combination of the number of groups and observations per group. This will let us know the relative contribution of making more comparisons versus having more data per group. When we do this, we get the heat map below.

![](https://i.imgur.com/9lFNSD5.png)

As we can see, 




