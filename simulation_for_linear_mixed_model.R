
####模拟数据#####

#实验假设
#
#
#
library(dplyr)
library(tidyr)
library(ggplot2)
library(purrr)
library(lme4)
library(lmerTest)
library(broom.mixed)
library(faux)
library(brms)

## 添加固定效应
subj_n = 30  # 被试数
b0 = 0.4      # 截距
b1 = 0.6      # 情绪变量的固定效应
b2 = 0.2      # 图片类型的固定效应
data <- add_random(subj = 30) %>%
  add_within("subj", type = c("positive", "negative"), .prob = c(8, 2)) %>%
  add_between("subj",emotion = c("depression", "anxiety"), .prob = c(6, 4)) %>%
  add_contrast("emotion", "treatment", add_cols = TRUE,colnames = "emo") %>%
  add_contrast("type", "treatment", add_cols = TRUE,colnames = "typ")

##添加随机效应
u0s= 0.1      # 情绪变量的随机截距值
u1s=0.2       # 情绪变量的随机斜率值
data <- data %>%
  # 添加关于被试的情绪变量的随机截距和随机斜率
  add_ranef(c("subj","emo"), u0s, u1s) %>%
  # 添加观察值的误差项
  add_ranef(sigma = 0.1)

###生成因变量
data <-data %>%
  mutate(ERP = b0 + (b1+u1s)*emo + b2* typ + u0s + sigma)

head(data,10)

##分析数据

m <- brm(ERP ~ emo + typ + (1 + emo | subj), data = data)
summary(m)
fixef(m)
ranef(m)

library(bayesplot)


##
#总体参数与估计参数的比较
plot(m)


