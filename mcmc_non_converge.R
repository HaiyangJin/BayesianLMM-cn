# 该代码用于展示 MCMC 链不收敛的情况
# 作者：潘晚坷
# https://github.com/HaiyangJin/BayesianLMM-cn


library(bayesplot)
library(posterior)

# 设置随机数种子以确保可重复性
set.seed(2023)

# 模拟生成4条不收敛的MCMC链
n_chains <- 4
chain_length <- 1000

chains <- array(0, dim = c(chain_length, n_chains,1))

for (i in 1:n_chains) {
  first_half <- rnorm(chain_length / 2, mean = 3, sd = 2)
  second_half <- rnorm(chain_length / 2, mean = 5, sd = 1)
  chains[, i, 1] <- c(first_half, second_half)
}
dimnames(chains)[[3]] <- c("sigma")

# 绘制4条链的轨迹图
mcmc_trace(chains)
# 计算rhat: 结果为 1.17 > 1.1
posterior::rhat( extract_variable_matrix(chains, "sigma") )
# 绘制自回归图
mcmc_acf()