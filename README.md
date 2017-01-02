# Applied financial modelling

This repository is created for sharing quantitative models which I have developed at a financial institution in Vietnam. Models are written in **R programming language**, some are built on **Visual Basics for Application (VBA)** and web applications are hosted on **shinyapps.io**. I share both data and R code so people interested in those models can test, modify or contribute to this project. All materials are free.

I hope this project could foster free education in quantitative finance!

## Models
The repository so far contains:
- Multifactor risk model
- Asset allocation models
- Interest rate models
- Time series models
- Nominal effective exchange rate (NEER)
- Neural networks

### Arbitrage pricing theory and factor models

What are factors that explain differences in return of assets?

This question is a central theme in financial economics. There are two prominent theories are CAPM and APT. CAPM states that correlation with market returns explain asset returns. APT, on the other hand, claims that there are many factors affecting asset returns, and market return is only one factor. In practice, portfolio managers usually implement APT models because they could actively bet on factors which they understand most, and hedge factors they consider risky.

How do we use factor models to solve real world problem?

Fixed income trading desks extensively use factor models to hedge yield curve risks, which are changes in shape of yield curve. Factor models could help traders reduce or increase exposure to specific tenors on a yield curve. For instance, a trader is confident about his forecast of 5-year treasury yield but not sure about other tenors, he would use factor models to design his portfolio which has least exposure to other tenor's movements.


### Asset allocation models

*Update soon*

### Interest rate models

Assets and Liabilities management in banking industry require robust simulation of interest rate movement. The results are used for asset allocation decision in banks. Researchers have invented numerous kind of models, including both univariate and multivariate models. However, banks choose interest rate models depending on complexity of their balance sheet. Sophisticated models do not necessarily perform better than simple ones.

In my experience, you should choose models based on realiability of your data. Bad data can ruin your effort.

### Time series forecast models

#### Univariate time series models

This type of model only use past values of one variable to predict future values. The most famous model is ARIMA. From my experience, univariate models perform better at forecasting high frequency time series. However, its power deteriorate quite quickly at long forecast horizon.

In practice, time series usually show long memory property, which means past values have long-lasting effects on future values. That property could make ARIMA model return poor forecast. Fortunately, ARFIMA model can fit those time series, and make far better forecast. You can see my model at R-code folder and modify it as you like.


#### Multivariate time series models

Multivariate models is ubiquitous in macroeconomic researchs. Two simplest models are Vector autoregressive model (VAR) and Vector Error Correction model (VECM). To use VAR, you need stationary time series which can be achieved by differences. In pratice, it is very common that data series are non stationary and cointegrated, so VECM could perform better at forecasting than VAR.

To apply multivariate time series models, you need to do the following steps:

1. Test whether your time series are stationary (Augmented Dicky Fuller test)
2. Test cointegration hypothesis (Johansen test)
3. Find the optimal order of autoregression
4. Estimate VAR model (VECM model if you find cointegrations among time series)
5. Diagnostic tests
6. Make forecast or analyse impulse response function(IRF)

You can use my data and R codes to practice all those steps.

### Nominal effective exchange rate (NEER)

Watching a currency in relation with a basket of currencies can reveal whether the currency is relatively stronger or weaker. However, many developing countries do not provide this kind of data. I have developed an application for this purpose. Although the code in this repository was written for Vietnam case, you can apply to another country as you wish by changing country names and currencies.

The application have 2 parts:
* Data feeds from IMF (DOTS database) and Google Finance (realtime exchange rate)

You can use Google spreadsheet to make a realtime exchange rate table like mine.

* Algorithm

There is no universal formula for NEER, organizations can produce different NEER values but trends are not much different. In this application, I chose Bank of England method published at May 1999 quarterly bulettin.

### Implicit currency weights

In many emerging country, central banks tend to claims that they pegged their currencies to a basket of currency. However, they never disclose weights of currencies in that baskets. That raise questions about inconsistency between central banks' talks and action. Fortunately, econometrics could help us find out whether central banks pegged their currencies to a basket or USD only.

### Forecast exchange rate using Artificial Neural Networks(ANN)

This is my current project. I would update R-code soon.


