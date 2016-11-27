#############################################################
#
# Effective exchange rate daily
# This file contains two parts: data downloading section and algorithm part
# Data source: OECD statistics; IMF Direction of Trade Statistics
# Algorithm: Bank of England method published at May 1999 quarterly bulettin
#
############################################################

library(jsonlite)
library(rsdmx)
library(zoo)
library(xts)


# Data loading

## Import and export data from IMF JSON file
## http://dataservices.imf.org/REST/SDMX_JSON.svc/CompactData/{database ID}/{frequency}.{item1 from
## dimension1}+{item2 from dimension1}+{item N from dimension1}.{item1 from
## dimension2}+{item2 from dimension2}+{item M from dimension2}?startPeriod={start
## date}&endPeriod={end date}


####################################################
# Import data from IMF server
counterpart.area<-c("US","1C_995","CN","JP","KR","SG","TW","TH")

indicators<-c("TXG_FOB_USD","TMG_CIF_USD")


## Create a function for download data from IMF DOTS
imf_dot<- function(indicator,country="VN",counterpart="US",start=1995,end=2016,freq="A")
{
  if(length(indicator)>1)
    stop("Only use one indicator a time", call.=TRUE)
  else {
    url<-paste("http://dataservices.imf.org/REST/SDMX_JSON.svc/CompactData/","DOT/",freq,".",country,".",indicator,"?startPeriod=",start,"&endPeriod=",end,sep="")
    data<-fromJSON(url)
    data<-as.data.frame(data)
    
    for (i in counterpart){
      temp<-subset(data,data$CompactData.DataSet.Series..COUNTERPART_AREA==i)
      temp<-as.data.frame(temp$CompactData.DataSet.Series.Obs)
      temp<-temp[,1:2]
      colnames(temp)<-c("year",i)
      if (grep(i,counterpart)==1)
        combined<-temp
      else {
        by_id<-colnames(temp)[1]
        combined<-merge(combined,temp,by=by_id,all=TRUE)
      }
    }
  }

  if (nrow(combined)==0)
    stop("No data found.",call.=TRUE)
  remove(data,temp,i)
  return(combined)
}

for (i in indicators){
  d<-imf_dot(indicator=i,country="VN",counterpart=counterpart.area,start=1995,end=2016,freq="A")
  d<-apply(d,2,as.numeric)
  assign(i,d)
}

## Save trade data
export<-TXG_FOB_USD
import<-TMG_CIF_USD
total<-(export[,-c(1)]+import[,-c(1)])
total.trade<-data.frame(year=as.numeric(export[,1]),total)
write.table(total.trade,file="trade.csv",row.names=FALSE)
remove(list=ls())
#####################################################


#####################################################
# Import data from csv file
total.trade<-read.csv("trade.csv",header=TRUE,sep="")

# Assign weights by year
weight<-total.trade[,-c(1)]/rowSums(total.trade[,-c(1)])

avg_weight<-data.frame(year=as.numeric(total.trade[,1])+1,weight)

avg_weight<-subset(avg_weight,avg_weight$year>=2000)

for (i in 1:nrow(avg_weight)) for (j in 2:ncol(avg_weight)){
  avg_weight[i,j]<-mean(weight[i:i+4,j-1])
}
####################################################


###################################################
# Update exchange rate database

stored_rate<-read.csv("exrate.csv",header=T,sep="")
stored_rate$date<-as.Date(stored_rate$date,format="%Y-%m-%d")

## retrieve exchange rate data from google spreadsheet

library(XML)
tf<-tempfile(tmpdir=tdir<-tempdir())

htmlurl<-"https://docs.google.com/spreadsheets/d/1Yd-GRRHo4NFNLk3yQwn-UWf34d9fCAbcpptxu7yVV4w/pubhtml?gid=2012954994&single=true"

download.file(htmlurl,tf)
rawhtml<-paste(readLines(tf),collapse="\n")
exrate<-readHTMLTable(rawhtml,header=NA,stringsAsFactors=F)
rate<-as.data.frame(exrate)
rate<-rate[,-c(1)]
colnames(rate)<-as.character(rate[1,])
rate<-rate[-c(1),]
rate[rate=="#N/A"]=NA
rate<-na.omit(rate)

##convert to Vietnam timezone
rate$date<-as.Date(rate$date,format="%m/%d/%Y")+1
rate[,2:ncol(rate)]<-apply(rate[,2:ncol(rate)],2,as.numeric)
rate<-rate[!grepl("Saturday",weekdays(rate$date)) & !grepl("Sunday",weekdays(rate$date)) ,]

final<-rbind(stored_rate,rate)

# save new exchaange rate data
write.table(final,file="exrate.csv",row.names=FALSE)
remove(htmlurl,rawhtml,exrate,rate)
#####################################################

rate<-stored_rate

# Convert currency against VND
eur<-rate$usdvnd*rate$eurusd
others<-rate$usdvnd/rate[,-c(1:3)]
vnd<-data.frame(rate$date,1/rate$usdvnd,1/eur,1/others)
colnames(vnd)<-c("date","usd","eur","cny","jpy","krw","sgd","twd","thb")

rate_change<-vnd[-c(1),-c(1)]/vnd[-c(nrow(vnd)),-c(1)]
rate_change<-data.frame(date=vnd$date[-c(1)],rate_change)

rate_weight<-rate_change
rate_weight$date<-format(rate_weight$date,"%Y")
colnames(rate_weight)[1]<-"year"

# Match weight for rate
library(plyr)
join<-join(rate_weight,avg_weight,by="year")

rate_weight<-join[,c(10:ncol(join))]
remove(join)

vector_power<-function(y,x){
  if (length(y)!=length(x))
    stop("Vectors need to have the same length",call.=TRUE)
  else{
    result<-c(1:length(y))
    for (i in 1:length(y)){
      result[i]<-y[i]^x[i]
      }
  }
  remove(i)
  return(result)
}

# Raise rate change by weight power
power<-matrix(data=NA,nrow=nrow(rate_change),ncol=ncol(rate_weight))

for (i in 1:nrow(rate_change)){
  power[i,]<-vector_power(as.numeric(rate_change[i,-c(1)]),as.numeric(rate_weight[i,]))
}


# NEER index
index<-apply(power,1,prod)
index<-c(1,index)

neer<-index
for (i in 2:length(index)){
  neer[i]<-neer[i-1]*index[i]
}

output<-data.frame(date=rate$date,neer=neer*100,usd=rate$usdvnd,cny=rate$usdcny,eur=rate$eurusd,jpy=rate$usdjpy)
write.table(output,file="neer.csv",row.names=FALSE)

# Plot results

library(googleVis)
library(reshape2)
neer<-melt(neer,id="date")

neer_gvis<-gvisAnnotationChart(neer,datevar="date",numvar="value",idvar="variable")
plot(neer_gvis)





