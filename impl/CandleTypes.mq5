//+------------------------------------------------------------------+
//|                                                  CandleTypes.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

/*
*/
  
int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
}

void OnTick(){
   if(hasNewCandle()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
      if(copiedPrice == 2){
         CandleInfo info = verifyTypeCandle(candles[0]);
         Print("info");
      }
   }
}

CandleInfo verifyTypeCandle(MqlRates& candle){
   CandleInfo info;
   ORIENTATION hammer = verifyIfHammer(candle, 20, 65);
   if(hammer == MEDIUM){
      if(verifyIfStrong(candle, 60)){
         //drawVerticalLine(TimeCurrent(), "strong" + IntegerToString(TimeCurrent()), clrYellow);
         info.type = STRONG;
      }else if(verifyIfWeak(candle, 30)){
        // drawVerticalLine(TimeCurrent(), "weak" + IntegerToString(TimeCurrent()), clrWhite);
         info.type = UNDECIDED;
      }else{
        // drawVerticalLine(TimeCurrent(), "weak" + IntegerToString(TimeCurrent()), clrBlue);
         info.type = WEAK;
      }
   
      if(verifyIfOpenBiggerThanClose(candle)){
         info.orientation = DOWN;
      }else{
         info.orientation = UP;
      }
   }else{
      info.type = HAMMER;
      info.orientation = hammer;
   }
   
   info.close = candle.close;
   info.open = candle.open;
   info.high = candle.high;
   info.low = candle.low;
   
   return info;
}

ORIENTATION verifyIfHammer(MqlRates& candle, double min, double max){
   double maxAreaHammer = MathAbs(candle.high - candle.low);
   double maxHead =  maxAreaHammer * (min / 100);
   double maxBody =  maxAreaHammer * (max / 100);
   datetime actualTime = candle.time;
   double stickH, stickL, head, body;
   
      //drawVerticalLine(actualTime, "hammer-" + actualTime, HAMMER_COLOR); 
   if(verifyIfOpenBiggerThanClose(candle)){
      stickH = MathAbs(candle.high - candle.open);
      stickL = MathAbs(candle.low - candle.close);
      head = MathAbs(candle.high - candle.close);
      body = MathAbs(candle.low - candle.close);
   }else{
      stickH = MathAbs(candle.high - candle.close);
      stickL = MathAbs(candle.low - candle.open);
      head = MathAbs(candle.high - candle.open);
      body = MathAbs(candle.low - candle.open);
   }
      
   if(stickH > stickL){      
      if(head < maxHead || body > maxBody){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, DOWN, clrRed); 
         return DOWN;
      }
   }else{
      if(head < maxHead || body > maxBody ){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, UP, clrRed); 
         return UP;
      }
   } 
   
   return MEDIUM;
}

  
bool verifyIfWeak(MqlRates& candle, double percentual){
   double candleSize = MathAbs(candle.high - candle.low);
   double candleArea = MathAbs(candle.open - candle.close);
   
   if(((candleArea * 100) / candleSize) < percentual){
      return false;
   }
   
   return true;
}

bool verifyIfStrong(MqlRates& candle, double percentual){
   double candleSize = MathAbs(candle.high - candle.low);
   double candleArea = MathAbs(candle.open - candle.close);
   
   if(((candleArea * 100) / candleSize) > percentual){
      return true;
   }
   
   return false;
}