//+------------------------------------------------------------------+
//|                                                MacroAnalisys.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input  ENUM_MA_METHOD MODE_AVERAGES = MODE_SMA;

#include "MainFunctionBackup.mqh"

double averageMD[], averageML[], averageMH[], averageMWL[], averageMWH[], averageMDL[], averageMDH[], averageMMH[], bordersAverage[40];
int handleMd, handleMh, handleMl, handleMmh, handleMml, handleMdh, handleMdl, handleMwh, handleMwl, countAverage = 0;
bool bordersDrawed = false;
int actualPosition = 0;
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      
      handleMh = iMA(_Symbol,PERIOD_M1,1,0,MODE_AVERAGES,PRICE_HIGH);
      handleMl = iMA(_Symbol,PERIOD_M1,1,0,MODE_AVERAGES,PRICE_LOW);
      handleMd = iMA(_Symbol,PERIOD_M1,1,0,MODE_AVERAGES,PRICE_CLOSE);
      
      handleMwh = iMA(_Symbol,PERIOD_W1,1,0,MODE_AVERAGES,PRICE_HIGH);
      handleMwl = iMA(_Symbol,PERIOD_W1,1,0,MODE_AVERAGES,PRICE_LOW);
      
      handleMdh = iMA(_Symbol,PERIOD_D1,1,0,MODE_AVERAGES,PRICE_HIGH);
      handleMdl = iMA(_Symbol,PERIOD_D1,1,0,MODE_AVERAGES,PRICE_LOW);
 
      handleMmh = iMA(_Symbol,PERIOD_MN1,1,0,MODE_AVERAGES,PRICE_HIGH);
      handleMml = iMA(_Symbol,PERIOD_MN1,1,0,MODE_AVERAGES,PRICE_LOW);

//---
   
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
void OnTick()
  {
   if(verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
      if(copiedPrice == 3){
         if(hasNewCandle()){
            if(!bordersDrawed){
               // draw(handleMml, handleMmh, "month");
              // draw(handleMdl, handleMdh, "day");
               draw(handleMwl, handleMwh, "week");
               bordersDrawed = true;
            }
            
            if(hasPositionOpen() == false){
               //DOWN
               double points, sl = STOP_LOSS, tp = TAKE_PROFIT;
               if(candles[0].close > candles[2].close && candles[0].close > candles[1].close && candles[1].close > candles[2].close ){
                  if(actualPosition-1 > 0 && candles[2].close < bordersAverage[actualPosition-1]){
                     points = calcPoints(bordersAverage[actualPosition-1], bordersAverage[actualPosition-2]);
                     if(points  > STOP_LOSS){
                        sl = points / 2;
                     }
                     if(points > TAKE_PROFIT){
                        tp = points;
                     }
                     realizeDeals(BUY, ACTIVE_VOLUME, sl, tp);
                     actualPosition = getPositionArray(candles[2].close);
                  }
               }else if(candles[0].close < candles[2].close && candles[1].close < candles[2].close && candles[0].close < candles[1].close ){
                  if(actualPosition+1 < countAverage && candles[2].close > bordersAverage[actualPosition]){
                     points = calcPoints(bordersAverage[actualPosition], bordersAverage[actualPosition+1]);
                     if(points / 2 > STOP_LOSS){
                        sl = points / 2;
                     }
                     if(points > TAKE_PROFIT){
                        tp = points;
                     }
                     realizeDeals(SELL, ACTIVE_VOLUME, sl, points);  
                     actualPosition = getPositionArray(candles[2].close);
                   }
               } 
            }else{
               activeStopMovelPerPoints(PONTUATION_ESTIMATE);
            }
         }
      }
   }else{
      closeBuyOrSell(0);
   }
//---
   
  }
  
int getPositionArray(double closePrice){
   int pos = actualPosition;
   for(int i = 0; i < countAverage; i++){
      if(i > 0 && closePrice >= bordersAverage[i-1] && closePrice <= bordersAverage[i]) {
         pos = i;
         break;
      } 
   } 
   
   return pos;
}

//+------------------------------------------------------------------+

void draw(int handleL, int handleH, string name){
   datetime now = TimeCurrent();
   double averageL[], averageH[], points;      
   int max = 0, min = 0;
   if(CopyBuffer(handleL,0,0,handleL,averageL) == handleL && CopyBuffer(handleH,0,0,handleH,averageH) == handleH){
      // max = ArrayMaximum(averageH,0,handleMmh);
      // min = ArrayMinimum(averageL,0,handleMml);
     // drawHorizontalLine(averageH[max], now, name + " border sup", clrYellow);
     // drawHorizontalLine(averageL[min], now, name + " border inf", clrYellow);
      ArraySort(averageL);
      ArraySort(averageH);
      handleL = (handleL > 20 ? 20 : handleL);
      for(int i = 0; i < handleL; i++){
        if(i > 0){
          points = calcPoints(averageL[i-1], averageL[i]);
          if(points >= 100){
            bordersAverage[countAverage] = averageL[i];
            countAverage++;    
            drawHorizontalLine(averageL[i], now, name + IntegerToString(i) + " border inf", clrYellow);
          }
        } /**/
      }
      
      handleH = (handleH > 20 ? 20 : handleH);
      for(int i = 0; i < handleH; i++){
        if(i > 0){
           points = calcPoints(averageH[i-1], averageH[i]);
           if(points >= 100){
              bordersAverage[countAverage] = averageH[i];
              countAverage++;
              drawHorizontalLine(averageH[i], now, name + IntegerToString(i) + " border sup", clrYellow);
           }
        }
            /* */
      }
   }
}
