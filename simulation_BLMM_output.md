这是标题
================
truetrue

{0@plus 0.2ex @minus 0.2ex}% {-}% {}{}}

# 1 假想的心理学实验

我们借助一个假想的实验来展示如何使用贝叶斯混合效应模型分析实验心理学的数据。该实验的目的是探究抑郁症患者加工不同类型图片的神经基础。在该实验中，我们招募了抑郁症患者和健康对照组被试各30人。所有的被试都观看了30张正性图片和30张负性图片，且每张图片呈现10次。在实验过程中，我们记录了被试的脑电。我们所关注的因变量是晚期正电位（late
positive potentials, LPP）的波幅。简单来说，这是一个2
(组别`group`：抑郁症患者`depression`、对照组；被试间`control`) $\times$
2 (图片类型`type`：正性`positive`、负性`negative`；被试内)
的混合实验设计。

## 1.1 模拟数据

我们采用 \[@debruineFauxSimulationFactorial2021\]
的`library(faux)`包生成该假想实验的数据。具体假定参数如下：

``` r
subj_n <- 60   # 总被试量：抑郁患者30人，健康对照组被试30人
trial_n <- 10  # 每张图片呈现的次数

# 固定效应
b0 <- 2.5      # 截距 (所有条件的均值)
b1 <- 4.2      # 图片类型的固定效应 (主效应)
b2 <- 4.5      # 组别的固定效应 (主效应)
b3 <- 2.4      # 图片类型与组别的交互作用
fixed_true <- c(b0,b2,b1,b3) 

# 随机效应
u0s <- 2    # 被试的随机截距
u1s <- 2    # 被试的随机斜率 (图片类型)
u_sd_subj_true <- c(u0s,u1s)

# 误差项
sigma <- 4
```

根据假定的实验设计和参数来生成模拟数据：

``` r
#生成假定实验的条件的数据矩阵
df_simu <- add_random(subj = subj_n) %>%
  # 添加被试的组别信息（被试间）
  add_between("subj", group = c("depression", "control")) %>%
  # 添加图片类型的信息（被试内）
  add_within("subj", type = c("negative","positive")) %>%
  # 每个图片呈现10次
  add_random(trial = trial_n) %>%
  # 图片类型的编码：负性=-0.5；正性=0.5
  add_contrast("type", "anova", colnames = "type_code") %>%
  # 被试组别的编码：抑郁症组=-0.5；控制组=0.5
  add_contrast("group", "anova",colnames = "group_code") %>% 
  # 添加基于被试的随机截距和斜率 (图片类型)
  add_ranef("subj", u0s = u0s, u1s = u1s, .cors=0.5) %>% 
  # 添加观察值的误差项
  add_ranef(sigma = sigma) %>% 
  # 最后根据设置的固定效应和随机效应参数值，生成因变量。
  mutate(LPP = (b0+u0s) +         # 截距
           (b1+u1s) * type_code + # 图片材料的斜率
           b2 * group_code +      # 组别的斜率
           b3 * type_code * group_code +   # 交互作用
           sigma)            #误差项

head(df_simu,10) #查看生成的数据矩阵
```

``` r
df_simu <- df_simu %>% 
  select(subj, group, type, LPP) # 去除冗余的信息
# 设定-0.5和0.5的编码
contrasts(df_simu$group) <- MASS::contr.sdif(2)
contrasts(df_simu$type) <- MASS::contr.sdif(2)

head(df_simu, 5)#查看数据结构
```

# 2 数据分析

接下来对数据进行建构贝叶斯线性混合效应模型。在这部分将使用`brms`的R包
\[@burknerBrmsPackageBayesian2017a\]
进行分析。`brms`目前常用贝叶斯模型分析之中
\[@burknerBayesianDistributionalNonLinear\]
\[@burknerAdvancedBayesianMultilevel2017\];
\[@ladislasIntroductionBayesianMultilevel2019\];
\[@vasishthBayesianDataAnalysis2018\]。关于`brms`包的更多详细内容可以见以下的网址
<https://paul-buerkner.github.io/brms/> 。

## 2.1 先验的设置

正如前文所述，在运用贝叶斯模型之前，我们需要先设置先验信息。而如何设置一个合适的先验信息对于初学者来说却是并不容易的事。先验分布是模型参数的预先设置的分布形态，它赋予了模型参数在数据分析之前相对合理性的信息，然后用数据的信息更新先验信息，以获得模型参数的后验信息。在我们的数据模型中需要建立\$
LPP = *{Intercepet}+*{group} X\_{group} + *{type} X*{type} +
sd\_{type}+sd\_{intecept} +
$这样的线性混合效应模型，那么需要指定固定截距$*{Intercept}$,固定斜率$beta*{group}\$,固定斜率
$\beta_{type}$以及误差项$\epsilon$，随机斜率$sd_{type}$，随机截距$sd_{intecept}$的先验分布。在`brms`中如果没有设置先验，那么会默认采用负无穷到正无穷的平均分布，但是这样极容易影响后验估计的准确性，致使得出错误的结论\[@veenmanBayesianHierarchicalModeling2022\]。在设置先验分布时，我们需要确定参数的先验分布的大致形状，常见的分布有二项分布、正态分布、泊松分布等。在设置先验分布之前，可以利用先验信息大致确定先验分布。具体方法可以参考\[@sarmaPriorSettingPractice2020\]。在这个例子中，我们预设参数是符合正态分布的。接着需要确定正态分布的平均数以及方差等超参数，这时需要进行先验预测（Prior
predictive
distribution），以检验所设置的超参数是否合适。我们可以采用`brms`包里面的`sample_prior ="only"`进行检验。
在`model_predict`中，`LPP`是因变量，`group`和`type`是自变量。`family`代表模型中使用的反应分布和相关函数。`prior`定义了模型的先验信息，如果不设置这个参数，那么模型建立中*先验*会默认使用均匀分布。`cores`当并行执行链时使用的核数，默认为1。`chains`
代表马尔可夫链的数量(默认为4)。`iter`参数用于马尔可夫链蒙特卡罗（Markov
Chain Monte Carlo ,
MCMC）算法的总迭代次数。`warmup`参数指定在过程开始时运行的迭代次数来校准MCMC，以便最后只保留`iter - warmup`
’迭代来近似后端分布的形状。如果想要了解更多，可以见
\[@McElreath:2016\]。
之后我们使用`pp_check`进行检验，看先数据分布（即因变量LPP的概率分布）的平均数（mean）、最大值（max），最小值（min）是否在先验预测分布中，如果平均数、最大值、最小值都包括在其内，那么这个先验分布的设置是合适的。关于prior的设置可具体参考`set_prior`函数对先验的设置。

``` r
## 定义先验分布
prior = c(
  prior(normal(0, 3), class = Intercept),
  prior(normal(0, 3), class = b),
  prior(normal(0, 3), class = sigma),
  prior(normal(0, 3), class = sd),
  prior(lkj(2), class = cor)
)
model_predict <- brm(LPP ~ group * type + (1 + type | subj), 
               data = df_simu,
               family="gaussian",
               cores = 4,
               chains = 4,
               warmup =1000,
               iter = 5000,
               sample_prior ="only",
               prior=prior)
```

    ## Compiling Stan program...

    ## Start sampling

    ## Using all posterior draws for ppc type 'stat' by default.

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![(#fig:pp_check-1)混合效应模型的均值、最大值、最小值的先验预测分布。
先验预测分布的均值、最小值和最大值的分布被标记为yrep](simulation_BLMM_output_files/figure-gfm/pp_check-1.png)

    ## Using all posterior draws for ppc type 'stat' by default.
    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![(#fig:pp_check-2)混合效应模型的均值、最大值、最小值的先验预测分布。
先验预测分布的均值、最小值和最大值的分布被标记为yrep](simulation_BLMM_output_files/figure-gfm/pp_check-2.png)

    ## Using all posterior draws for ppc type 'stat' by default.
    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![(#fig:pp_check-3)混合效应模型的均值、最大值、最小值的先验预测分布。
先验预测分布的均值、最小值和最大值的分布被标记为yrep](simulation_BLMM_output_files/figure-gfm/pp_check-3.png)
从图(fig:pp_check)可知，先验分布是合适的。如果觉得与实际数据的分布相差还是很大，可以再次调整预设的先验分布的超参数，再查看目前先验预测的分布是否符合设想的参数分布，如果不合适可调整至合适的参数为止。

## 2.2 添加固定效应

为了更好地理解贝叶斯混合线性模型，首先我们建立只有固定效应的模型。`model_1`中`brm`函数后的参数设置参见先验的设置部分的说明。与先验的设置不同，在模型建立中采用`sample_prior ="yes"`,以期纳入现有数据的分布影响，从而得到数据模型的后验分布。`summary`可以帮助我们展示模型拟合后的参数情况。`plot`可以显示模型拟合后的参数的分布情况以及MCMC情况的图示化结果。

``` r
# 定义参数的先验信息
prior <- c(
  prior(normal(0, 3), class = Intercept),
  prior(normal(0, 3), class = b),
  prior(normal(0, 3), class = sigma)
)
#建立模型
model_1 <- brm(LPP ~ group * type, 
               data = df_simu,
               family="gaussian",
               cores = 4,
               chains = 4,
               warmup = 1000,
               iter = 5000,
               sample_prior ="yes",
               prior = prior)
```

    ## Compiling Stan program...

    ## Start sampling

    ##  Family: gaussian 
    ##   Links: mu = identity; sigma = identity 
    ## Formula: LPP ~ group * type 
    ##    Data: df_simu (Number of observations: 1200) 
    ##   Draws: 4 chains, each with iter = 5000; warmup = 1000; thin = 1;
    ##          total post-warmup draws = 16000
    ## 
    ## Population-Level Effects: 
    ##                  Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## Intercept            2.26      0.13     2.00     2.52 1.00    20544    12561
    ## group2M1             4.70      0.26     4.19     5.22 1.00    20882    12027
    ## type2M1              4.30      0.27     3.78     4.82 1.00    20535    12456
    ## group2M1:type2M1     2.43      0.53     1.40     3.46 1.00    19192    11930
    ## 
    ## Family Specific Parameters: 
    ##       Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## sigma     4.60      0.09     4.42     4.79 1.00    20143    11816
    ## 
    ## Draws were sampled using sampling(NUTS). For each parameter, Bulk_ESS
    ## and Tail_ESS are effective sample size measures, and Rhat is the potential
    ## scale reduction factor on split chains (at convergence, Rhat = 1).

`Population-Level Effects`代表固定效应部分参数的后验情况。Intercept
代表模型中的固定截距。`group2M1`参数估计代表$\beta_{(group)}$，指的是组别变量的固定斜率。`type2M1`参数估计代表$\beta_{(type)}$，指的是图片类型变量的固定斜率。而`group2M1`以及`type2M1`中的`2M1`代表组别之间以及类型之间的效应的相减，即$\beta_{(Control-Depression)}$或者$\beta_{(Positive-Negative)}$。
`group2M1:type2M1`代表组别和图片类型交互作用的固定斜率。`Estimate`表示参数的估计值，`Est.Error`代表估计值的标准误。`l-95% CI`和`u-95% CI`代表参数的可信区间。`sigma`代表残差项的后验分布参数。
`Rhat`代表参数的收敛情况。在模型拟合的数据中如果Rhat\>1.01说明模型的收敛情况并不理想，Rhat应该尽量接近于1，这说明模型的收敛情况较好，但是尽量不要超过1.01。另外也可以使用`bayestestR`
包的函数进行判断模型的收敛情况。

``` r
if (!require(bayestestR)) {library(bayestestR)}
post_diag<- diagnostic_posterior(model_1)
effectsize::interpret_rhat(post_diag$Rhat)
```

<caption>

Table 2.1:

</caption>

<div custom-style="Table Caption">

*model_1的后验均值, 标准误, 95%的可信区间以及Rhat*

</div>

|                        | 后验均值 | 标准误 | 下限  | 上限  | Rhat  |  Bulk_ESS  |  Tail_ESS  |
|------------------------|:--------:|:------:|:-----:|:-----:|:-----:|:----------:|:----------:|
| 截距                   |  2.257   | 0.133  | 1.996 | 2.521 | 1.000 | 20,543.751 | 12,561.350 |
| $\beta_{(group)}$      |  4.704   | 0.264  | 4.191 | 5.220 | 1.001 | 20,881.789 | 12,026.712 |
| $\beta_{(type)}$       |  4.297   | 0.266  | 3.777 | 4.819 | 1.000 | 20,534.936 | 12,455.706 |
| $\beta_{(group:type)}$ |  2.427   | 0.530  | 1.396 | 3.461 | 1.000 | 19,191.813 | 11,930.285 |

表
@ref(tab:Table_1)显示了model_1拟合后的参数的后验情况，包括后验分布均值，标准误，95%的可信区间以及Rhat。

![(#fig:plot_model_1)左列是参数的后验分布图，右列是参数抽样的轨迹图。](simulation_BLMM_output_files/figure-gfm/plot_model_1-1.png)

图
@ref(fig:plot_model_1)描述了model_1中固定截距、固定斜率、残差的后验分布以及MCMC抽样情况。图的左边是参数的后验分布，x轴代表参数值；图的右边是逼近后验分布的两个行为的模拟(即4条链的轨迹图)，x轴代表迭代数，y轴代表参数值。这轨迹图显示了平均值周围的随机波动。

## 2.3 添加随机效应

接下来在后面的模型中加入一些随机效应。而随机效应项一般是由随机截距和随机斜率组成。正如前文提到随机效应的设置是为了更好地排除由个体差异的因素所带来的影响，这样可以使固定效应的参数更加精准的估计。在`brms`包中提供了对随机效应设置的语法，我们可以在`brm`函数采用`(1 | xxx )`类似的结构进行设置随机截距，`xxx`可以设置随机变量，如被试`subj`或者实验因素`type`，而在我们需要建立的模型中，我们只对subj指定了随机截距。然后在`1`后加上需要设置随机斜率的因子，
如`（1 + type | subj）`。下面我们在上述模型中添加随机截距。

``` r
prior = c(
  prior(normal(0, 3), class = Intercept),
  prior(normal(0, 3), class = b),
  prior(normal(0, 3), class = sigma),
  prior(normal(0, 3), class = sd)
)
model_2 <- brm(LPP ~ group * type + (1 |subj), 
               data = df_simu,
               family="gaussian",
               cores = 4,
               chains = 4,
               warmup =1000,
               iter = 5000,
               sample_prior ="yes",
               prior = prior)
```

    ## Compiling Stan program...

    ## Start sampling

``` r
summary(model_2)#查看参数情况
plot(model_2)   #查看每个参数的分布和抽样情况
```

![](simulation_BLMM_output_files/figure-gfm/unnamed-chunk-10-1.png)<!-- -->![](simulation_BLMM_output_files/figure-gfm/unnamed-chunk-10-2.png)<!-- -->

    ##  Family: gaussian 
    ##   Links: mu = identity; sigma = identity 
    ## Formula: LPP ~ group * type + (1 | subj) 
    ##    Data: df_simu (Number of observations: 1200) 
    ##   Draws: 4 chains, each with iter = 5000; warmup = 1000; thin = 1;
    ##          total post-warmup draws = 16000
    ## 
    ## Group-Level Effects: 
    ## ~subj (Number of levels: 60) 
    ##               Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## sd(Intercept)     2.01      0.23     1.61     2.52 1.00     6251     7844
    ## 
    ## Population-Level Effects: 
    ##                  Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## Intercept            2.24      0.28     1.70     2.80 1.00     6719     9770
    ## group2M1             4.58      0.57     3.46     5.70 1.00     6061     8877
    ## type2M1              4.30      0.24     3.83     4.78 1.00    36786    11100
    ## group2M1:type2M1     2.45      0.47     1.54     3.37 1.00    37518    11407
    ## 
    ## Family Specific Parameters: 
    ##       Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## sigma     4.17      0.09     4.01     4.35 1.00    30894    11299
    ## 
    ## Draws were sampled using sampling(NUTS). For each parameter, Bulk_ESS
    ## and Tail_ESS are effective sample size measures, and Rhat is the potential
    ## scale reduction factor on split chains (at convergence, Rhat = 1).

`Population-Level Effects`是model_2的固定效应部分，解释与`model_1`类似。与`model_1`不同，`model_2`加入了随机截距部分。
`Group-Level Effects`则是随机截距的参数的后验分布情况。

然后在`model_2`模型的代码基础之上加上随机斜率,探究在不同被试下图片类型对LPP波幅的影响。

``` r
prior = c(
  prior(normal(0, 3), class = Intercept),
  prior(normal(0, 3), class = b),
  prior(normal(0, 3), class = sigma),
  prior(normal(0, 3), class = sd),
  prior(lkj(2), class = cor)
)
model_3 <- brm(LPP ~ group * type + (1 + type | subj), 
               data = df_simu,
               family="gaussian",
               cores = 4,
               chains = 4,
               warmup =1000,
               iter = 5000,
               sample_prior ="yes",
               prior=prior)
```

    ## Compiling Stan program...

    ## Start sampling

``` r
summary(model_3)#查看参数情况
plot(model_3) #查看每个参数的后验分布和抽样情况
```

![](simulation_BLMM_output_files/figure-gfm/unnamed-chunk-12-1.png)<!-- -->![](simulation_BLMM_output_files/figure-gfm/unnamed-chunk-12-2.png)<!-- -->

``` r
plot(model_3, variable = "^b", regex = TRUE)#查看固定效应部分的参数分布情况
```

![](simulation_BLMM_output_files/figure-gfm/unnamed-chunk-12-3.png)<!-- -->

    ##  Family: gaussian 
    ##   Links: mu = identity; sigma = identity 
    ## Formula: LPP ~ group * type + (1 | subj) 
    ##    Data: df_simu (Number of observations: 1200) 
    ##   Draws: 4 chains, each with iter = 5000; warmup = 1000; thin = 1;
    ##          total post-warmup draws = 16000
    ## 
    ## Group-Level Effects: 
    ## ~subj (Number of levels: 60) 
    ##               Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## sd(Intercept)     2.01      0.23     1.61     2.52 1.00     6251     7844
    ## 
    ## Population-Level Effects: 
    ##                  Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## Intercept            2.24      0.28     1.70     2.80 1.00     6719     9770
    ## group2M1             4.58      0.57     3.46     5.70 1.00     6061     8877
    ## type2M1              4.30      0.24     3.83     4.78 1.00    36786    11100
    ## group2M1:type2M1     2.45      0.47     1.54     3.37 1.00    37518    11407
    ## 
    ## Family Specific Parameters: 
    ##       Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
    ## sigma     4.17      0.09     4.01     4.35 1.00    30894    11299
    ## 
    ## Draws were sampled using sampling(NUTS). For each parameter, Bulk_ESS
    ## and Tail_ESS are effective sample size measures, and Rhat is the potential
    ## scale reduction factor on split chains (at convergence, Rhat = 1).

`Population-Level Effects`是model_3的固定效应部分，解释与`model_1`类似。与`model_2`不同，`model_2`加入了随机斜率部分。
`Group-Level Effects`则是随机截距以及随机斜率参数的后验分布情况。

至此我们已经完成了线性混合效应模型的建构。

# 3 模型拟合效果与真实值比较

在这部分，我们验证一下模型拟合效果，将模型拟合参数与预设的参数真实值之间进行对比。

``` r
#比较固定效应中各参数与之前设置的总体参数（即真实值）之间的比较。
as.data.frame(model_3) %>%
  select(starts_with("b_")) %>%
  mcmc_recover_hist(true = fixed_true) 
#比较预设的被试随机效应总体参数(即真实值)和拟合的被试的随机效应的估计参数。
as.data.frame(model_3) %>%
  select(starts_with("sd_subj")) %>%
  mcmc_recover_hist(true = u_sd_subj_true) 
```

``` r
#比较固定效应中各参数与预设的总体参数（即真实值）之间的比较。
as.data.frame(model_3) %>%
  select(starts_with("b_")) %>%
  mcmc_recover_hist(true = fixed_true) 
```

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![(#fig:plot_mode_comparion_1)固定效应中各参数与之前设置的总体参数（即真实值）之间的比较](simulation_BLMM_output_files/figure-gfm/plot_mode_comparion_1-1.png)

``` r
as.data.frame(model_3) %>%
  select(starts_with("sd_subj")) %>%
  mcmc_recover_hist(true = u_sd_subj_true) 
```

    ## `stat_bin()` using `bins = 30`. Pick better value with `binwidth`.

![(#fig:plot_mode_comparion_2)预设的被试随机效应总体参数(即真实值)和拟合的被试的随机效应的估计参数](simulation_BLMM_output_files/figure-gfm/plot_mode_comparion_2-1.png)

<a href="mailto:从图@ref" class="email">从图@ref</a>(fig:plot_mode_comparion_1)<a href="mailto:和图@ref" class="email">和图@ref</a>(fig:plot_mode_comparion_2)中可知,模型拟合的参数的分布还是包含预设值的，这表明模型拟合度还是比较好的。不过对于研究者来说，更重要的还是想比较组间差异：两组之间的LPP波幅是否存在显著性的差异。我们可以通过贝叶斯因子（Bayesian
factor,BF）对模型拟合的一些参数进行比较
\[@heckReviewApplicationsBayes2022\];
\[@schadWorkflowTechniquesRobust2022\];
\[@wagenmakersBayesianHypothesisTesting2010\]，从而更好地观察两个组相关的自变量因素对因变量是否存在差异，这样更能够解释两组之间是否存在差异。

# 4 组间差异以及组内差异的比较

研究中通常需要比较组间差异或者组内各条件的差异。使用贝叶斯模型进行组间或者组内条件比较时需要注意，在贝叶斯线性混合效应模型中，一般可以将组间条件和组内条件的参数纳入，从而比较组间因素与组内因素相关的参数。我们可以通过`library(BayestestR)`
\[@makowskiBayestestRDescribingEffects2019\]
计算模型中的可信区间、最大后验概率估计(Maximum A Posteriori,
MAP)、显著性方向概率(Probability of Direction,
pd)、全后验分布百分比（percentage of the full posterior
distribution,ROPE）、贝叶斯因子（Bayes factor, BF）等
\[@makowskiIndicesEffectExistence2019\]。在贝叶斯模型参数比较中，比较推荐报告以上的指标
\[@makowskiIndicesEffectExistence2019\]。ROPE中的百分比是一个重要的指数，它一定程度上可以作为显著性指数的标准
\[@makowskiIndicesEffectExistence2019\]。关于除ROPE指标外其他贝叶斯模型模型参数报告的更多详细内容可见
<https://easystats.github.io/bayestestR/articles/guidelines.html>。

``` r
describe_posterior(model_3,centrality = "all", dispersion = TRUE,ci =0.95,test = "all")
```

使用`describe_posterior`可以输出贝叶斯模型比较的参数情况。从以上的输出可知，在两组比较中，我们会发现，$\beta_{group}$参数的ROPE的百分比小于1%，这说明我们可以拒绝零假设，两组之间存在显著的差异性。而$\beta_{(type)}$的ROPE的百分比也小于1%，这说明我们可以拒绝零假设，抑郁症患者和健康对照组中正性图片和负性图片存在显著性的差异，即组内各条件存在显著性差异。

当然在心理学研究中，有不少的贝叶斯统计的支持者主张使用贝叶斯因子进行假设检验
\[@rouderBayesianInferencePsychology2018\]。在以下的代码中我们将采用直接计算贝叶斯因子对组间差异以及组内差异进行检验。使用`brms`的`hypothesis`函数便可直接进行假设检验，并从中提取出贝叶斯因子。

通过`hypothesis$Evid.Ratio`，我们可以得到$BF_{01}$，而$BF_{10}$ = 1/
$BF_{01}$。在$\beta_{(group)}$
以及$\beta_{(type)}$中，$BF_{01}$\>0且\<1，则$BF_{10}$则趋于无穷大，这表明越支持备择假设，说明在组间和组内都存在显著的差异。

# 5 模型拟合常见问题

## 5.1 模型不收敛

模型不能收敛时，需要考虑是否模型建立得过于复杂，可以适当减少模型纳入的参数，达到简化模型。

## 5.2 模型比较

在数据处理中，我们纳入不同的参数，建立不同的贝叶斯混合线性模型。如何判断构建的哪种模型比较好，这便需要进行模型比较了。在贝叶斯分析中，常用LOOIC指标进行判断
\[@vehtariPracticalBayesianModel2017\]。在brms的R包中，我们可以采用loo函数进行计算LOOIC。数值越小，代表模型拟合度越佳。

``` r
loo_compare(loo(model_1),loo(model_2),loo(model_3))
```

    ##         elpd_diff se_diff
    ## model_3    0.0       0.0 
    ## model_2  -18.9       6.6 
    ## model_1 -112.3      14.4

## 5.3 缺失值处理

由于实验操作过程中难免会出现失误，可能最后数据中难免出现缺失值。最简单的解决方法无非是将缺失的地方进行删除，但是如果该数值并不是完全随机缺失的，这就可能导致数据分析中出现偏差。一般可以采用两种方法处理缺失值。一是在模型拟合之前将缺失值进行多重插值；二是在模型拟合过程中进行动态地进行缺失值的多重插值。这个可以采用`mi`函数进行多重插值。更多详细内容可以参考https://cran.r-project.org/web/packages/brms/vignettes/brms_missings.html。

# 6 References