# Applied financial modelling

This repository is created for sharing quantitative models which I have developed at a financial institution in Vietnam. Models are written in **R programming language**, some are built on **Visual Basics for Application (VBA)** and web applications are hosted on **shinyapps.io**. I share both data and R code so people interested in those models can test, modify or contribute to this project. All materials are free.

Hope this project could foster free education in quantitative finance!

## Models
The repository so far contains:
- Multifactor risk model
- Asset allocation models
- Interest rate models
- Time series models
- Nominal effective exchange rate (NEER)
- Neural networks

### Arbitrage pricing theory and factor models

*Update soon*

### Asset allocation models

*Update soon*

### Interest rate models

*Update soon*

### Time series forecast models

#### Univariate time series models

This type of model only use past values of one variable to predict future values. The most famous model is ARIMA. From my experience, univariate models perform better at forecasting high frequency time series. However, its power deteriorate quite quickly at long forecast horizon.

In practice, time series usually show long memory property, which means past values have long-lasting effects on future values. That property could make ARIMA model return poor forecast. Fortunately, ARFIMA model can fit those time series amazingly, and return far better forecast. You can see my model at R-code folder and modify it as you like.


#### Multivariate time series models

Multivariate model is ubiquitous in macroeconomic researchs. Two simplest models are Vector autoregressive model (VAR) and Vector Error Correction model (VECM). To use VAR you need stationary time series, which can be achieved by differences. In pratice, it is very common that data series are non stationary and cointegrated, so VECM could perform better at forecasting than VAR.

VECM is very useful in analysing macroeconomics policy and forecasting. To apply it you need to do the following steps:

1. Test whether your time series are stationary (Augmented Dicky Fuller test)
2. Tes cointegration hypothesis (Johansen test)
3. Find the optimal order of autoregression
4. Estimate VAR model (VECM model if you find cointegrated among time series)
5. Diagnostic test
6. Make forecast or analyse impulse response fucntion(IRF)

You can use my data and R codes to practice all those steps.


### Nominal effective exchange rate (NEER)

Watching a currency in relation with a basket of currencies can reveal whether the currency is relatively stronger or weaker. However, many developing countries do not provide this kind of data. I have developed an application for this purpose. Although the code in this repository was written for Vietnam case, you can apply to another country as you wish by changing country names and currencies.

The application have 2 parts:
* Data feeds from IMF (DOTS database) and Google Finance (realtime exchange rate)

To make a realtime exchange rate table like mine, you can use Google spreadsheet.

* Algorithm

There is no universal formula for NEER, organizations can produce different NEER values but trends are almost the same. In this application, I chose Bank of England method published at May 1999 quarterly bulettin.

### Forecast exchange rate using Artificial Neural Networks(ANN)

This is my current project after I have found that ANN could improve exchange rate forecast accuracy considerably. I would update R-code soon.


