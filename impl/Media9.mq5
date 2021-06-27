//+------------------------------------------------------------------+
//|                                                        Media.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionsBackup.mqh"

input  ENUM_MA_METHOD MODE_AVERAGES = MODE_SMA;

double averageML[], averageMH[], averageMD[], averageMDD[];
int handleMh, handleMl, handleMd, handleMdd, countAverage = 3;
ORIENTATION orientationMacroMedia = MEDIUM;
datetime startedDatetimeMediaRobot = 0;
ResultOperation resultDealsRobotMedia;
BordersOperation bordersMediaRobot;
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
     handleMd = iMA(_Symbol,PERIOD_CURRENT,PERIOD,0,MODE_AVERAGES,PRICE_CLOSE);
     handleMdd = iMA(_Symbol,PERIOD_CURRENT,PERIOD,2,MODE_AVERAGES,PRICE_CLOSE);
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
   
   if(verifyTimeToProtection()){
      if(hasNewCandle()){
         waitNewCandleMedia--;
      }else{
         if(waitNewCandleMedia < 0){
            orientationMacroMedia = startMediaRobot();
         }
         Print("");
      }
   }
}

ORIENTATION startMediaRobot(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
   if(copiedPrice == 3){
      if( CopyBuffer(handleMd,0,0,3,averageMD) == 3 && CopyBuffer(handleMdd,0,0,3,averageMDD) == 3){
         if(hasPositionOpen() == false){
            double points = MathAbs(calcPoints(averageMD[2], averageMDD[2]));
            
            if( candles[2].close > bordersMediaRobot.max || candles[2].close < bordersMediaRobot.min){
               if(bordersMediaRobot.min != 0 && candles[2].close < bordersMediaRobot.min && calcPoints(bordersMediaRobot.min, candles[2].close) > PONTUATION_ESTIMATE * 0.1 ){
                  orientationMacroMedia = DOWN;
               }else if(bordersMediaRobot.min != 0 && candles[2].close > bordersMediaRobot.max && calcPoints(candles[2].close, bordersMediaRobot.max) > PONTUATION_ESTIMATE * 0.1){
                  orientationMacroMedia = UP;
               }
               
               bordersMediaRobot = getBordersChannel(candles[2].close);
            }
            if(averageMD[0] > averageMDD[0] && averageMD[2] < averageMDD[2] && points > 5){
              // if(verifyIfOpenBiggerThanClose(candles[0]) &&  verifyIfOpenBiggerThanClose(candles[1])){
               if(verifyIfOpenBiggerThanClose(candles[0]) && verifyIfOpenBiggerThanClose(candles[1])){
                  if(orientationMacroMedia != UP){
                     toBuyOrToSellMediaRobot(DOWN, STOP_LOSS, TAKE_PROFIT);
                  }
               }
            }else if(averageMD[0] < averageMDD[0] && averageMD[2] > averageMDD[2] && points > 5){
               if(!verifyIfOpenBiggerThanClose(candles[0]) &&  !verifyIfOpenBiggerThanClose(candles[1]) && orientationMacroMedia == UP){
                  if(orientationMacroMedia != DOWN){
                     toBuyOrToSellMediaRobot(UP, STOP_LOSS, TAKE_PROFIT);
                  }
               }
            }
         }else{
           if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){ 
               double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
               if(averageMD[0] > averageMD[2] && averageMDD[0] < averageMDD[2] &&
                   averageMD[0] > averageMDD[0] && averageMD[2] < averageMDD[2]){
                   //waitNewCandleMedia = WAIT_CANDLES;
                   closeBuyOrSell(0);
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
               double entryDeal = PositionGetDouble(POSITION_PRICE_OPEN);
               if(averageMD[0] < averageMD[2] && averageMDD[0] > averageMDD[2] &&
                   averageMD[0] < averageMDD[0] && averageMD[2] > averageMDD[2]){
                   //waitNewCandleMedia = WAIT_CANDLES;
                   closeBuyOrSell(0);
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
     waitNewCandleMedia = WAIT_CANDLES;
   //  numBarsMedia = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
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

BordersOperation getBordersChannel(double price){
   BordersOperation borders;
   borders.instantiated = false;
   if(START_PRICE_CHANNEL > 0){
      double distance = (price - START_PRICE_CHANNEL) /_Point;
      int points = (int)(distance / PONTUATION_ESTIMATE);
      double diff = 0;
      
      if(points < 0){
         borders.max = START_PRICE_CHANNEL + (points * PONTUATION_ESTIMATE * _Point);
         borders.min = START_PRICE_CHANNEL + ((points - 1) * PONTUATION_ESTIMATE * _Point);
      }else if(points > 0){
         borders.min = START_PRICE_CHANNEL + (points * PONTUATION_ESTIMATE * _Point);
         borders.max = START_PRICE_CHANNEL + ((points + 1) * PONTUATION_ESTIMATE * _Point);
      }else{
         borders.max = START_PRICE_CHANNEL + ( PONTUATION_ESTIMATE * _Point);
         borders.min = START_PRICE_CHANNEL;
      }
         
      drawHorizontalLine(borders.max, 0, "borderMax", clrAquamarine); 
      drawHorizontalLine(borders.min, 0, "borderMin", clrAquamarine); 
      drawHorizontalLine(price, 0, "price", clrWhite); 
        
      borders.central = price;
      borders.instantiated = true;
   }

   return borders;
}