//+------------------------------------------------------------------+
//|                                                   Fibonnacci.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input double INIT_POINT = 1.19959;
input double END_POINT = 1.19851;

double initPoint = INIT_POINT;
double endPoint = END_POINT;


double fiboPoints[6] = {0, 23.6, 38.2, 50, 61.8, 100};
double FiboValues[6];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      calculateBordersFibonacci(initPoint, endPoint);
   
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
//---
      int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
       if(copiedPrice == 1){
          if(candles[0].close > initPoint + initPoint * 0.1){
            initPoint = initPoint + (initPoint * (fiboPoints[1] / 100));
            calculateBordersFibonacci(initPoint, endPoint);
         }
      }   
  }
//+------------------------------------------------------------------+


void calculateBordersFibonacci(double initPoint, double endPoint){
   double points = (endPoint - initPoint) / _Point;
   string nameLineFibo = "fibo";
   
   // normal
   if(points > 0){
     for(int i = 0; i <= 5; i++){
         ObjectDelete(0,nameLineFibo);
         if(i == 0){
            FiboValues[i]  = initPoint;
         }else if(i == 5){
            FiboValues[i]  = endPoint;
         }else{ 
            FiboValues[i]  = (endPoint - (points * _Point * fiboPoints[i]) / 100);
         }
         drawHorizontalLine(FiboValues[i], TimeCurrent(), nameLineFibo + IntegerToString(i), clrWhite);
     } 
   }else{ // invertido
     for(int i = 5; i >= 0; i--){
         ObjectDelete(0,nameLineFibo);
         if(i == 0){
            FiboValues[5-i]  = endPoint;
         }else if(i == 5){
            FiboValues[5-i]  = initPoint;
         }else{
            FiboValues[5-i]  = (endPoint + (MathAbs(points) * _Point * fiboPoints[i]) / 100);
         }
         drawHorizontalLine(FiboValues[i], TimeCurrent(), nameLineFibo + IntegerToString(i), clrWhite);
     }
   }
   
   Print("dsadas");
   
}