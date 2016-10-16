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

export<-TXG_FOB_USD
import<-TMG_CIF_USD
total<-(export[,-c(1)]+import[,-c(1)])
total.trade<-data.frame(year=as.numeric(export[,1]),total)


## retrieve exchange rate data from google spreadsheet

library(googlesheets)
library(dplyr)
mysheets<-gs_ls()
mysheets %>% glimpse()
gap<-gs_title("Exchange rate")
gs_ws_ls(gap)
exrate<-gap %>% gs_read(ws="Exrate")

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
rate<-rate[!grepl("#N/A",rate$usdkrw),]
##convert to Vietnam timezone
rate$date<-as.Date(rate$date,format="%m/%d/%Y")+1
rate[,2:ncol(rate)]<-apply(rate[,2:ncol(rate)],2,as.numeric)
rate<-rate[!grepl("Saturday",weekdays(rate$date)) & !grepl("Sunday",weekdays(rate$date)) ,]







