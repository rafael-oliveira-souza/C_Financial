//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input  ENUM_MA_METHOD MODE_AVERAGES = MODE_SMA;

double averageML[], averageMH[], averageMD[], averageMDD[], averageMDA[];
int handleMh, handleMl, handleMd, handleMdd, handleMda, countAverage = 3;
ORIENTATION orientationMacroMedia = MEDIUM;
datetime startedDatetimeMediaRobot = 0;
ResultOperation resultDealsRobotMedia;
double valueDealEntryPriceMedia = 0;
int waitNewCandleMedia = 0;
bool waitSecondClose = false;
int lastDayMediaRobot = 0;
ulong numBarsMedia = 0;
bool achievedGain = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     resultDealsRobotMedia.total = 0;
     startedDatetimeMediaRobot = TimeCurrent();
     handleMh = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_HIGH);
     handleMl = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_LOW);
     handleMd = iMA(_Symbol,PERIOD_CURRENT,PERIOD/2,0,MODE_AVERAGES,PRICE_CLOSE);
     handleMdd = iMA(_Symbol,PERIOD_CURRENT,PERIOD/2,2,MODE_AVERAGES,PRICE_CLOSE);
     handleMda = iMA(_Symbol,PERIOD_CURRENT,PERIOD/2,4,MODE_AVERAGES,PRICE_CLOSE);
  //---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   /**/
   
   if(verifyTimeToProtection()){
      if(hasNewCandle()){
         waitNewCandleMedia--;
      }else{
         if(waitNewCandleMedia < 0){
            orientationMacroMedia = startMediaRobot();
            if(hasPositionOpen()){
               int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
               if(copiedPrice == 2){
                  if(CopyBuffer(handleMd,0,0,3,averageMD) == 3 && CopyBuffer(handleMdd,0,0,3,averageMDD) == 3  && CopyBuffer(handleMda,0,0,3,averageMDA) == 3){
                     datetime actualTime = TimeCurrent();
                     //ORIENTATION or1 = verifyAverage(averageMD[0], averageMD[1]); 
                    // ORIENTATION or2 = verifyAverage(averageMD[1], averageMD[2]); 
                    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
                        double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
                        if(averageMDD[0] > averageMD[0] && averageMDA[0] < averageMD[0]){
                           drawVerticalLine(actualTime, "Decision" + IntegerToString(actualTime), clrAquamarine);
                           closeBuyOrSell(0);
                           if(verifyResultTrade()){
                            // verifyIfOpenDealAgainst(DOWN, candles[1].close, entryDeal, averageMD[2], averageMDD[2], averageMDA[2]);
                           }
                        }
                     }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                        double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
                        if(averageMDD[0] < averageMD[0] && averageMDA[0] > averageMD[0] ){
                           drawVerticalLine(actualTime, "Decision" + IntegerToString(actualTime), clrAquamarine);
                           closeBuyOrSell(0);
                           if(verifyResultTrade()){
                             //verifyIfOpenDealAgainst(UP, candles[1].close, entryDeal, averageMD[2], averageMDD[2], averageMDA[2]);
                           }
                        }
                     }
                  }
               }
            }
         }
      }
  }else{
      closeBuyOrSell(0);
  }
}

ORIENTATION startMediaRobot(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
   if(copiedPrice == 2){
      if(hasPositionOpen() == false){
         if(CopyBuffer(handleMh,0,0,1,averageMH) == 1 &&  CopyBuffer(handleMl,0,0,1,averageML) == 1 &&  CopyBuffer(handleMd,0,0,2,averageMD) == 2){
            orientationMacroMedia = verifyAverage(averageMD[0], averageMD[1]);
            datetime actualTime = TimeCurrent();
            if(orientationMacroMedia == UP){
               if(averageMD[0] < averageML[0] &&  averageMD[1] >= averageML[0]){
                  drawVerticalLine(actualTime, "Decision" + IntegerToString(actualTime), clrYellow);
                  toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT); 
               }
            }else if(orientationMacroMedia == DOWN){
               if(averageMD[0] > averageMH[0] && averageMD[1] <= averageMH[0]){
                  drawVerticalLine(actualTime, "Decision" + IntegerToString(actualTime), clrYellow);
                  toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT); 
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

void toBuyOrToSellMediaRobot(ORIENTATION orient, double stopLoss, double takeProfit){
  toBuyOrToSell(orient,ACTIVE_VOLUME,stopLoss,takeProfit);
  if(verifyResultTrade()){
     valueDealEntryPriceMedia = 0;
     waitNewCandleMedia = 1;
     numBarsMedia = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
  }
}
//+------------------------------------------------------------------+

ORIENTATION verifyAverage(double prevAv, double actualAv){
   if(prevAv > actualAv){
      return DOWN;
   }else if(prevAv < actualAv) {
      return UP;
   } else{
      return MEDIUM;
   }
   
}

void verifyIfOpenDealAgainst(ORIENTATION orient, double price, double entryDeal, double averMD, double averMDD, double averMDA){
   if( entryDeal != 0){
      datetime actualTime = TimeCurrent();
      if(orient == UP){
         /*if(price < entryDeal){
             drawVerticalLine(actualTime, "inversion" + IntegerToString(actualTime), clrWhite);
             waitNewCandleMedia = WAIT_CANDLES;
             if(AGAINST_CURRENT == ON){
                toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT);
             }
         }else{
             toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT);
         }*/
      }else if(orient == DOWN){
         /*
         if(price > entryDeal){
             drawVerticalLine(actualTime, "inversion" + IntegerToString(actualTime), clrWhite);
             waitNewCandleMedia = WAIT_CANDLES;
             if(AGAINST_CURRENT == ON){
                toBuyOrToSellMediaRobot(UP, STOP_LOSS/2, TAKE_PROFIT/2);
             }
         }else{
             toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT);
         }*/
      } 
   }
}

bool verifyResultToday(){
    int actDay = getActualDay(startedDatetimeMediaRobot);
    if(lastDayMediaRobot == actDay){
       if(!achievedGain){
          double total = calcTotal();
          if(total !=  resultDealsRobotMedia.total){
            resultDealsRobotMedia.total = total;
            bool resultAchieved = verifyResultPerDay(total);
            
            if(resultAchieved){
               achievedGain = true;
               Print("Lucro do dia atingido");
            }
            
            return resultAchieved;
          }
       }else{
          return  achievedGain;
       }
   }else{
       achievedGain = false;
       lastDayMediaRobot = actDay;
       resultDealsRobotMedia.total = 0;
       startedDatetimeMediaRobot = TimeCurrent();
   }
   
   return false;
}